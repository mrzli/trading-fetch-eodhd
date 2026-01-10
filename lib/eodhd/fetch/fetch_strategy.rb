# frozen_string_literal: true

require "json"
require "set"
require "time"

require_relative "../../util"
require_relative "../shared/path"
require_relative "shared"
require_relative "fetch_exchange_data"
require_relative "fetch_splits"
require_relative "fetch_dividends"

module Eodhd
  class FetchStrategy
    INTRADAY_MAX_RANGE_SECONDS = 118 * 24 * 60 * 60
    INTRADAY_MIN_CSV_LENGTH = 20

    def initialize(log:, cfg:, api:, io:)
      @log = log
      @cfg = cfg
      @api = api
      @io = io
      @shared = FetchShared.new(cfg: cfg, io: io)
      @fetch_exchange_data = FetchExchangeData.new(log: log, api: api, io: io, shared: @shared)
      @fetch_splits = FetchSplits.new(log: log, api: api, io: io, shared: @shared)
      @fetch_dividends = FetchDividends.new(log: log, api: api, io: io, shared: @shared)
    end
∏
    def run
      symbol_entries = @fetch_exchange_data.fetch

      @fetch_splits.fetch(symbol_entries)
      @fetch_dividends.fetch(symbol_entries)

      fetch_eod(symbol_entries)
      fetch_intraday(symbol_entries)
    end

    private

    def fetch_eod(symbol_entries)
      symbol_entries.each do |entry|
        if !@shared.should_fetch?(entry)
          next
        end

        fetch_eod_single(entry)
      end
    end

    def fetch_eod_single(symbol_entry)
      exchange = Validate.required_string("exchange", symbol_entry[:exchange])
      type = Validate.required_string("type", symbol_entry[:type])
      symbol = Validate.required_string("symbol", symbol_entry[:symbol])

      symbol_with_exchange = "#{symbol}.#{exchange}"
      relative_path = Path.raw_eod_data(exchange, symbol)

      unless @shared.file_stale?(relative_path)
        @log.info("Skipping EOD (fresh): #{relative_path}")
        return
      end

      begin
        @log.info("Fetching EOD CSV: #{symbol_with_exchange} (#{type})...")
        csv = @api.get_eod_data_csv(exchange, symbol)
        saved_path = @io.save_csv(relative_path, csv)
        @log.info("Wrote #{saved_path}")
      rescue StandardError => e
        @log.warn("Failed EOD for #{symbol_with_exchange}: #{e.class}: #{e.message}")
      ensure
        @shared.pause_between_requests
      end
    end

    def fetch_intraday(_symbol_entries)
      symbol = "AAPL"
      exchange = "US"
      symbol = Validate.required_string("symbol", symbol)
      exchange = Validate.required_string("exchange", exchange)

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

          saved_path = @io.save_csv(relative_path, csv)
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

    def intraday_from_seconds_from_path(relative_path)
      base = File.basename(relative_path.to_s, ".csv")
      DateUtil.datetime_to_seconds(base)
    rescue ArgumentError
      nil
    end
  end
end
