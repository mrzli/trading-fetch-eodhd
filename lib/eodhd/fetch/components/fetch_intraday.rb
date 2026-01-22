# frozen_string_literal: true

require_relative "../../../util"
require_relative "../../shared/path"

module Eodhd
  class FetchIntraday
    INTRADAY_MAX_RANGE_SECONDS = 118 * 24 * 60 * 60
    INTRADAY_MIN_CSV_LENGTH = 20

    def initialize(log:, api:, io:, shared:)
      @log = log
      @api = api
      @io = io
      @shared = shared
    end

    def fetch(symbol_entries)
      symbol_entries.each do |entry|
        next unless @shared.should_fetch?(entry)
        fetch_single(entry)
      end
    end

    private

    def fetch_single(symbol_entry)
      exchange = symbol_entry[:exchange]
      symbol = symbol_entry[:symbol]

      symbol_with_exchange = "#{symbol}.#{exchange}"

      begin
        latest_from_on_disk = latest_intraday_raw_from_seconds(exchange, symbol)

        to = Time.now.to_i
        while to > 0 do
          from = [0, to - INTRADAY_MAX_RANGE_SECONDS].max

          if !latest_from_on_disk.nil? && from <= latest_from_on_disk
            latest_from_formatted = DateUtil.seconds_to_datetime(latest_from_on_disk)
            @log.info("Stopping intraday fetch (already have newer data): #{symbol_with_exchange} (from=#{DateUtil.seconds_to_datetime(from)} <= latest_from=#{latest_from_formatted})")
            break
          end

          relative_path = Path.raw_intraday_data(exchange, symbol, from)

          from_formatted = DateUtil.seconds_to_datetime(from)
          to_formatted = DateUtil.seconds_to_datetime(to)
          @log.info("Fetching intraday CSV: #{symbol_with_exchange} (from=#{from_formatted} to=#{to_formatted})...")

          csv = @api.get_intraday_csv(exchange, symbol, from: from, to: to)

          if csv.to_s.length < INTRADAY_MIN_CSV_LENGTH
            @log.info("Stopping intraday history fetch (short CSV, length=#{csv.to_s.length}): #{symbol_with_exchange} (from=#{from_formatted} to=#{to_formatted})")
            break
          end

          saved_path = @io.write_csv(relative_path, csv)
          @log.info("Wrote #{saved_path}")

          to = from - 1
          @shared.pause_between_requests
        end
      rescue StandardError => e
        @log.warn("Failed intraday for #{symbol_with_exchange}: #{e.class}: #{e.message}")
      ensure
        @shared.pause_between_requests
      end
    end

    def latest_intraday_raw_from_seconds(exchange, symbol)
      exchange = Validate.required_string("exchange", exchange)
      symbol = Validate.required_string("symbol", symbol)

      raw_dir = Path.raw_intraday_data_dir(exchange, symbol)
      raw_paths = @io.list_relative_paths(raw_dir)

      raw_paths
        .select { |path| path.end_with?(".csv") }
        .map do |path|
          base_name = File.basename(path, ".csv")
          DateUtil.datetime_to_seconds(base_name)
        end
        .max
    end

  end
end
