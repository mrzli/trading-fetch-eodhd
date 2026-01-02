# frozen_string_literal: true

require "json"
require "set"

module Eodhd
  class Processor
    EXCLUDED_EXCHANGE_CODES = Set.new(["MONEY"]).freeze

    def initialize(log:, cfg:, api:, io:)
      @log = log
      @cfg = cfg
      @api = api
      @io = io
    end

    def fetch_exchanges_list
      relative_path = Eodhd::Path.exchanges_list

      if file_stale?(relative_path: relative_path)
        @log.info("Fetching exchanges list...")
        fetched = @api.get_exchanges_list_json!
        saved_path = @io.save_json!(
          relative_path: relative_path,
          json: fetched,
          pretty: true
        )
        @log.info("Wrote #{saved_path}")
        fetched
      else
        @log.info("Skipping exchanges list (fresh): #{relative_path}")
        @io.read_text(relative_path: relative_path)
      end
    end

    def exchange_codes_from(exchanges_json)
      exchanges = JSON.parse(exchanges_json)
      unless exchanges.is_a?(Array)
        raise TypeError, "Expected exchanges list JSON to be an Array, got #{exchanges.class}"
      end

      exchanges.filter_map do |exchange|
        next unless exchange.is_a?(Hash)

        code = exchange["Code"].to_s.strip
        next if code.empty?

        if EXCLUDED_EXCHANGE_CODES.include?(code)
          @log.debug("Skipping excluded exchange: #{code}")
          next
        end

        code
      end
    end

    def fetch_symbols_for_exchanges(exchange_codes:)
      exchange_codes.each do |exchange_code|
        fetch_symbols_for_exchange(exchange_code: exchange_code)
      end
    end

    def fetch_eod
      symbol = "MCD"

      ["US", "NYSE"].each do |exchange|
        symbol_with_exchange = "#{symbol}.#{exchange}"
        relative_path = Eodhd::Path.eod_data(exchange: exchange, symbol: symbol)

        unless file_stale?(relative_path: relative_path)
          @log.info("Skipping EOD (fresh): #{relative_path}")
          return
        end

        begin
          @log.info("Fetching EOD JSON: #{symbol_with_exchange}...")
          json = @api.get_eod_data_json!(exchange: exchange, symbol: symbol)
          saved_path = @io.save_json!(relative_path: relative_path, json: json, pretty: true)
          @log.info("Wrote #{saved_path}")
          return
        rescue StandardError => e
          @log.warn("Failed EOD for #{symbol_with_exchange}: #{e.class}: #{e.message}")
        ensure
          pause_between_requests
        end
      end
    end

    private

    def fetch_symbols_for_exchange(exchange_code:)
      exchange_code = Validate.required_string!("exchange_code", exchange_code)

      existing_paths = symbols_paths_for_exchange(exchange_code: exchange_code)
      if existing_paths.any? && existing_paths.none? { |path| file_stale?(relative_path: path) }
        @log.info("Skipping symbols (fresh): #{File.join('symbols', exchange_code_kebab(exchange_code), '*.json')}")
        return
      end

      begin
        symbols_json = @api.get_exchange_symbol_list_json!(exchange_code: exchange_code)

        symbols = JSON.parse(symbols_json)
        unless symbols.is_a?(Array)
          raise TypeError, "Expected symbols JSON to be an Array, got #{symbols.class}"
        end

        groups = symbols.group_by do |symbol|
          next "unknown" unless symbol.is_a?(Hash)

          raw_type = symbol["Type"]
          type = Eodhd::StringUtil.kebab_case(raw_type)
          type = "unknown" if type.empty?
          type
        end

        groups.each do |type, items|
          relative_path = Eodhd::Path.exchange_symbol_list(exchange_code: exchange_code, type: type)
          saved_path = @io.save_json!(
            relative_path: relative_path,
            json: JSON.generate(items),
            pretty: true
          )
          @log.info("Wrote #{saved_path}")
        end
      rescue StandardError => e
        @log.warn("Failed symbols for #{exchange_code}: #{e.class}: #{e.message}")
      ensure
        pause_between_requests
      end
    end

    def exchange_code_kebab(exchange_code)
      Eodhd::StringUtil.kebab_case(exchange_code)
    end

    def symbols_paths_for_exchange(exchange_code:)
      relative_dir = File.join("symbols", exchange_code_kebab(exchange_code))

      @io
        .list_relative_paths(relative_dir: relative_dir)
        .select { |path| path.end_with?(".json") }
    end

    def pause_between_requests
      return unless @cfg.request_pause_ms.positive?
      sleep(@cfg.request_pause_ms / 1000.0)
    end

    def file_stale?(relative_path:)
      last_updated_at = @io.file_last_updated_at(relative_path: relative_path)
      return true if last_updated_at.nil?

      min_age_seconds = @cfg.min_file_age_minutes.to_i * 60
      (Time.now - last_updated_at) >= min_age_seconds
    end
  end
end
