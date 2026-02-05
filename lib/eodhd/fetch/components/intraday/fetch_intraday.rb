# frozen_string_literal: true

require_relative "../../../../util"
require_relative "../../../shared/path"
require_relative "../../../parsing/intraday_csv_parser"
require_relative "fetch_intraday_shared"

module Eodhd
  class FetchIntraday
    DAYS_TO_SECONDS = 24 * 60 * 60
    RANGE_SECONDS = 118 * DAYS_TO_SECONDS
    STRIDE_SECONDS = 110 * DAYS_TO_SECONDS

    def initialize(container:, shared:)
      @log = container.logger
      @api = container.api
      @io = container.io
      @data_reader = container.data_reader

      @shared = shared

      @intraday_shared = FetchIntradayShared.new(container: container)
    end

    def fetch(recheck_start_date:, parallel:, workers:)
      symbol_entries = @data_reader.symbols
      filtered_entries = symbol_entries.filter { |entry| @shared.should_fetch_symbol_intraday?(entry) }

      fetch_intraday_for_symbols(
        filtered_entries,
        recheck_start_date: recheck_start_date,
        parallel: parallel,
        workers: workers
      )
    end

    private

    def fetch_intraday_for_symbols(symbol_entries, recheck_start_date:, parallel:, workers:)
      ParallelExecutor.execute(symbol_entries, parallel: parallel, workers: workers) do |entry|
        fetch_single_symbol(entry, recheck_start_date: recheck_start_date)
      end
    end

    def fetch_single_symbol(symbol_entry, recheck_start_date:)
      exchange = symbol_entry[:exchange]
      symbol = symbol_entry[:symbol]

      symbol_with_exchange = "#{symbol}.#{exchange}"

      begin
        fetched_dir = Path.raw_intraday_fetched_symbol_data_dir(exchange, symbol)
        @io.delete_dir(fetched_dir)

        first_ts = first_existing_timestamp(exchange, symbol)

        if !first_ts.nil? && recheck_start_date
          if should_restart_from_scratch?(exchange, symbol, first_ts, symbol_with_exchange)
            delete_all_processed_files(exchange, symbol, symbol_with_exchange)
            first_ts = nil
          end
        end

        last_ts = first_ts || last_existing_timestamp(exchange, symbol)

        to = Time.now.to_i
        while to > 0 do
          from = [0, to - RANGE_SECONDS].max

          if !last_ts.nil? && to <= last_ts
            latest_to_formatted = DateUtil.seconds_to_datetime(last_ts)
            @log.info("Stopping intraday fetch (already have newer data): #{symbol_with_exchange} (from=#{DateUtil.seconds_to_datetime(from)} <= latest_to=#{latest_to_formatted})")
            break
          end

          fetch_valid = fetch_intraday_interval(exchange, symbol, from, to)
          break unless fetch_valid

          to = to - STRIDE_SECONDS
        end
      rescue StandardError => e
        @log.warn("Failed intraday for #{symbol_with_exchange}: #{e.class}: #{e.message}")
      end
    end

    def fetch_intraday_interval(exchange, symbol, from, to)
      csv = @intraday_shared.fetch_intraday_interval_csv(exchange, symbol, from, to)
      return false if csv.nil?

      rows = IntradayCsvParser.parse(csv)
      if rows.empty?
        @log.info("Stopping intraday history fetch (empty CSV): #{symbol_with_exchange} #{from_to_message_fragment}")
        return nil
      end

      parsed_from = rows.first[:timestamp]
      parsed_to = rows.last[:timestamp]

      relative_path = Path.raw_intraday_fetched_symbol_data(exchange, symbol, parsed_from, parsed_to)
      saved_path = @io.write_csv(relative_path, csv)
      @log.info("Wrote #{saved_path}")

      true
    end

    def first_existing_timestamp(exchange, symbol)
      files = sorted_processed_files(exchange, symbol)
      return nil if files.empty?

      first_file = files.first
      # Extract year-month from filename (format: YYYY-MM.csv)
      base_name = File.basename(first_file, ".csv")
      year, month = base_name.split("-").map(&:to_i)

      # Return first second of that month
      Time.new(year, month, 1, 0, 0, 0, "+00:00").to_i
    end

    def last_existing_timestamp(exchange, symbol)
      files = sorted_processed_files(exchange, symbol)
      return nil if files.empty?

      last_file = files.last
      # Extract year-month from filename (format: YYYY-MM.csv)
      base_name = File.basename(last_file, ".csv")
      year, month = base_name.split("-").map(&:to_i)

      # Return last second of that month
      next_month = month + 1
      next_year = year
      if next_month > 12
        next_month = 1
        next_year += 1
      end

      Time.new(next_year, next_month, 1, 0, 0, 0, "+00:00").to_i - 1
    end

    def sorted_processed_files(exchange, symbol)
      processed_dir = Path.raw_intraday_processed_symbol_data_dir(exchange, symbol)
      @io.list_relative_files(processed_dir)
        .filter { |path| path.end_with?(".csv") }
        .sort
    end

    def should_restart_from_scratch?(exchange, symbol, processed_start_ts, symbol_with_exchange)
      # Fetch a range around the processed start date to check if the start date has changed
      check_from = [0, processed_start_ts - RANGE_SECONDS / 2].max
      check_to = processed_start_ts + RANGE_SECONDS

      @log.info("Rechecking start date for #{symbol_with_exchange} around #{DateUtil.seconds_to_datetime(processed_start_ts)}")

      csv = @intraday_shared.fetch_intraday_interval_csv(exchange, symbol, check_from, check_to)
      return false if csv.nil?

      rows = IntradayCsvParser.parse(csv)
      return false if rows.empty?

      new_start_ts = rows.first[:timestamp]

      if new_start_ts != processed_start_ts
        @log.warn("Start date changed for #{symbol_with_exchange}: old=#{DateUtil.seconds_to_datetime(processed_start_ts)}, new=#{DateUtil.seconds_to_datetime(new_start_ts)}")
        return true
      end

      @log.info("Start date unchanged for #{symbol_with_exchange}")
      false
    end

    def delete_all_processed_files(exchange, symbol, symbol_with_exchange)
      processed_dir = Path.raw_intraday_processed_symbol_data_dir(exchange, symbol)
      @io.delete_dir(processed_dir)
      @log.info("Deleted all processed files for #{symbol_with_exchange} due to start date change")
    end

  end
end
