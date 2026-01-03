# frozen_string_literal: true

require "json"
require "set"

module Eodhd
  class Processor
    UNSUPPORTED_EXCHANGE_CODES = Set.new(["MONEY"]).freeze

    SYMBOL_INCLUDED_EXCHANGES = Set.new(["US"]).freeze
    SYMBOL_INCLUDED_REAL_EXCHANGES = Set.new(["NYSE", "NASDAQ"]).freeze
    SYMBOL_INCLUDED_TYPES = Set.new(["common-stock"]).freeze

    INTRADAY_MAX_RANGE_SECONDS = 118 * 24 * 60 * 60

    def initialize(log:, cfg:, api:, io:)
      @log = log
      @cfg = cfg
      @api = api
      @io = io
    end

    def fetch!
      fetch_exchanges_list!
      exchange_codes = get_exhange_codes

      fetch_symbols_for_exchanges!(exchange_codes)
      symbol_entries = get_symbol_entries(exchange_codes)

      fetch_eod!(symbol_entries)
      fetch_intraday!(symbol_entries)
    end

    private

    def fetch_exchanges_list!
      relative_path = Path.exchanges_list

      if file_stale?(relative_path)
        @log.info("Fetching exchanges list...")
        fetched = @api.get_exchanges_list_json!
        saved_path = @io.save_json!(relative_path, fetched, true)
        @log.info("Wrote #{saved_path}")
      else
        @log.info("Skipping exchanges list (fresh): #{relative_path}.")
      end
    end

    def get_exhange_codes
      exchanges_text = @io.read_text(Path.exchanges_list)
      exchanges = JSON.parse(exchanges_text)
      exchanges.filter_map do |exchange|
        code = exchange["Code"].to_s.strip
        next if UNSUPPORTED_EXCHANGE_CODES.include?(code)
        code
      end
    end

    def fetch_symbols_for_exchanges!(exchange_codes)
      exchange_codes.each do |exchange_code|
        fetch_symbols_for_exchange!(exchange_code)
      end
    end

    def fetch_symbols_for_exchange!(exchange_code)
      exchange_code = Validate.required_string!("exchange_code", exchange_code)

      existing_paths = symbols_paths_for_exchange(exchange_code)
      if existing_paths.any? && existing_paths.none? { |path| file_stale?(path) }
        @log.info("Skipping symbols (fresh): #{File.join('symbols', StringUtil.kebab_case(exchange_code), '*.json')}")
        return
      end

      begin
        symbols_text = @api.get_exchange_symbol_list_json!(exchange_code)
        symbols = JSON.parse(symbols_text)

        symbols_by_type = symbols.group_by do |symbol|
          raw_type = symbol["Type"]
          type = StringUtil.kebab_case(raw_type)
          type = "unknown" if type.empty?
          type
        end

        symbols_by_type.each do |type, items|
          relative_path = Path.exchange_symbol_list(exchange_code, type)
          saved_path = @io.save_json!(relative_path, JSON.generate(items), true)
          @log.info("Wrote #{saved_path}")
        end
      rescue StandardError => e
        @log.warn("Failed symbols for #{exchange_code}: #{e.class}: #{e.message}")
      ensure
        pause_between_requests
      end
    end

    def symbols_paths_for_exchange(exchange_code)
      relative_dir = File.join("symbols", StringUtil.kebab_case(exchange_code))

      @io
        .list_relative_paths(relative_dir)
        .select { |path| path.end_with?(".json") }
    end

    def get_symbol_entries(exchange_codes)
      exchange_codes.flat_map do |exchange_code|
        exchange_code = Validate.required_string!("exchange_code", exchange_code)

        relative_dir = File.join("symbols", StringUtil.kebab_case(exchange_code))

        @io
          .list_relative_paths(relative_dir)
          .select { |path| path.end_with?(".json") }
          .sort
          .flat_map do |relative_path|
            type = File.basename(relative_path, ".json")

            symbols_file_text = @io.read_text(relative_path)
            symbol_entries = JSON.parse(symbols_file_text)

            symbol_entries.map do |entry|
              {
                exchange: exchange_code,
                real_exchange: entry["Exchange"],
                type: type,
                symbol: entry["Code"]
              }
            end
          end
      end
    end

    def fetch_eod!(symbol_entries)
      symbol_entries.each do |entry|
        exchange_code = Validate.required_string!("exchange", entry[:exchange])
        real_exchange_code = Validate.required_string!("real_exchange", entry[:real_exchange])
        type = Validate.required_string!("type", entry[:type])
        symbol = Validate.required_string!("symbol", entry[:symbol])

        symbol_with_exchange = "#{symbol}.#{exchange_code}"
        relative_path = Path.eod_data(exchange_code, symbol)

        if (
          !SYMBOL_INCLUDED_EXCHANGES.include?(exchange_code) or
          !SYMBOL_INCLUDED_REAL_EXCHANGES.include?(real_exchange_code) or
          !SYMBOL_INCLUDED_TYPES.include?(type)
        )
          next
        end

        unless file_stale?(relative_path)
          @log.info("Skipping EOD (fresh): #{relative_path}")
          next
        end

        begin
          @log.info("Fetching EOD CSV: #{symbol_with_exchange} (#{type})...")
          csv = @api.get_eod_data_csv!(exchange_code, symbol)
          saved_path = @io.save_csv!(relative_path, csv)
          @log.info("Wrote #{saved_path}")
        rescue StandardError => e
          @log.warn("Failed EOD for #{symbol_with_exchange}: #{e.class}: #{e.message}")
        ensure
          pause_between_requests
        end
      end
    end

    def fetch_intraday!(_symbol_entries)
      symbol_with_exchange = "AAPL.US"
      symbol, exchange_code = symbol_with_exchange.split(".", 2)
      symbol = Validate.required_string!("symbol", symbol)
      exchange_code = Validate.required_string!("exchange", exchange_code)

      relative_dir = Path.intraday_data_dir(exchange_code, symbol)
      @io.delete_dir!(relative_dir)

      begin
        to = Time.now.to_i
        while to > 0 do
          from = [0, to - INTRADAY_MAX_RANGE_SECONDS].max
          relative_path = Path.intraday_data(exchange_code, symbol, from)

          from_formatted = DateUtil.utc_compact_datetime(from)
          to_formatted = DateUtil.utc_compact_datetime(to)
          @log.info("Fetching intraday CSV: #{symbol_with_exchange} (from=#{from_formatted} to=#{to_formatted})...")

          csv = @api.get_intraday_csv!(symbol_with_exchange, from: from, to: to)
          saved_path = @io.save_csv!(relative_path, csv)
          @log.info("Wrote #{saved_path}")

          to = from - 1
          pause_between_requests
        end
      rescue StandardError => e
        @log.warn("Failed intraday for #{symbol_with_exchange}: #{e.class}: #{e.message}")
      ensure
        pause_between_requests
      end
    end

    def pause_between_requests
      return unless @cfg.request_pause_ms.positive?
      sleep(@cfg.request_pause_ms / 1000.0)
    end

    def file_stale?(relative_path)
      last_updated_at = @io.file_last_updated_at(relative_path)
      return true if last_updated_at.nil?

      min_age_seconds = @cfg.min_file_age_minutes.to_i * 60
      (Time.now - last_updated_at) >= min_age_seconds
    end
  end
end
