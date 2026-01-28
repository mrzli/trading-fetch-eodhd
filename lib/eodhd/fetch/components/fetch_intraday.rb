# frozen_string_literal: true

require_relative "../../../util"
require_relative "../../shared/path"
require_relative "../../parsing/intraday_csv_parser"

module Eodhd
  class FetchIntraday
    DAYS_TO_SECONDS = 24 * 60 * 60
    RANGE_SECONDS = 118 * DAYS_TO_SECONDS
    STRIDE_SECONDS = 110 * DAYS_TO_SECONDS
    MIN_CSV_LENGTH = 20

    def initialize(container:, shared:)
      @log = container.logger
      @api = container.api
      @io = container.io
      @shared = shared
    end

    def fetch(symbol_entries)
      symbol_entries.each do |entry|
        next unless @shared.should_fetch_symbol?(entry)
        fetch_single_symbol(entry)
      end
    end

    private

    def fetch_single_symbol(symbol_entry)
      exchange = symbol_entry[:exchange]
      symbol = symbol_entry[:symbol]

      symbol_with_exchange = "#{symbol}.#{exchange}"

      begin
        latest_timestamp = latest_existing_timestamp(exchange, symbol)

        to = Time.now.to_i
        while to > 0 do
          from = [0, to - RANGE_SECONDS].max

          if !latest_timestamp.nil? && to <= latest_timestamp
            latest_to_formatted = DateUtil.seconds_to_datetime(latest_timestamp)
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

    def latest_existing_timestamp(exchange, symbol)
      raw_dir = Path.raw_intraday_fetched_symbol_data_dir(exchange, symbol)
      raw_paths = @io.list_relative_files(raw_dir)
      if raw_paths.empty?
        return nil
      end

      raw_paths
        .filter { |path| path.end_with?(".csv") }
        .map do |path|
          base_name = File.basename(path, ".csv")
          to_str = base_name.split("__", 2).last
          DateUtil.datetime_to_seconds(to_str)
        end
        .max
    end

    def fetch_intraday_interval(exchange, symbol, from, to)
      symbol_with_exchange = "#{symbol}.#{exchange}"

      from_formatted = DateUtil.seconds_to_datetime(from)
      to_formatted = DateUtil.seconds_to_datetime(to)
      @log.info("Fetching intraday CSV: #{symbol_with_exchange} (from=#{from_formatted} to=#{to_formatted})...")

      csv = @api.get_intraday_csv(exchange, symbol, from: from, to: to)

      if csv.to_s.length < MIN_CSV_LENGTH
        @log.info("Stopping intraday history fetch (short CSV, length=#{csv.to_s.length}): #{symbol_with_exchange} (from=#{from_formatted} to=#{to_formatted})")
        return false
      end

      relative_path = relative_intraday_path(exchange, symbol, csv)
      if relative_path.nil?
        @log.info("Stopping intraday history fetch (empty CSV): #{symbol_with_exchange} (from=#{from_formatted} to=#{to_formatted})")
        return false
      end

      saved_path = @io.write_csv(relative_path, csv)
      @log.info("Wrote #{saved_path}")

      true
    end

    def relative_intraday_path(exchange, symbol, csv)
      rows = IntradayCsvParser.parse(csv)
      return nil if rows.empty?

      parsed_from = rows.first[:timestamp]
      parsed_to = rows.last[:timestamp]

      Path.raw_intraday_fetched_symbol_data(exchange, symbol, parsed_from, parsed_to)
    end

  end
end
