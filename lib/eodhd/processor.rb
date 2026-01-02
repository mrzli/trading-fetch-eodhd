# frozen_string_literal: true

require "json"
require "set"

module Eodhd
  class Processor
    attr_reader :symbols_index

    def initialize(log:, cfg:, api:, io:)
      @log = log
      @cfg = cfg
      @api = api
      @io = io

      @exchanges_list_parser = ExchangesListParser.new(log: log)
      @exchange_symbol_list_parser = ExchangeSymbolListParser.new(log: log)
      @symbol_codes_parser = SymbolCodesParser.new(log: log)
    end

    def fetch!
      fetch_exchanges_list!
      exchange_codes = get_exhange_codes
      fetch_symbols_for_exchanges!(exchange_codes)
      @symbols_index = symbol_codes_index(exchange_codes)

      fetch_eod
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
      exchanges_json = @io.read_text(Path.exchanges_list)
      @exchanges_list_parser.exchange_codes_from_json(exchanges_json)
    end

    # Returns a nested Hash of:
    # - first level keys: exchange codes (as provided)
    # - second level keys: symbol types (derived from filenames under symbols/<exchange>/)
    # - third level values: array of symbol codes extracted from each file's entries ("Code" field)
    def symbol_codes_index(exchange_codes)
      exchange_codes.each_with_object({}) do |exchange_code, acc|
        exchange_code = Validate.required_string!("exchange_code", exchange_code)
        relative_dir = File.join("symbols", StringUtil.kebab_case(exchange_code))

        type_to_codes = @io
          .list_relative_paths(relative_dir)
          .select { |path| path.end_with?(".json") }
          .sort
          .each_with_object({}) do |relative_path, type_acc|
            type = File.basename(relative_path, ".json")
            type_acc[type] = symbol_codes_from_file(relative_path)
          end

        acc[exchange_code] = type_to_codes
      end
    end

    public :symbol_codes_index

    def symbol_codes_from_file(relative_path)
      json = @io.read_text(relative_path)
      @symbol_codes_parser.codes_from_json(json, source: relative_path)
    rescue StandardError => e
      @log.warn("Failed to read symbols file: #{relative_path}: #{e.class}: #{e.message}") if @log.respond_to?(:warn)
      []
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
        symbols_json = @api.get_exchange_symbol_list_json!(exchange_code)

        groups = @exchange_symbol_list_parser.group_by_type_from_json(symbols_json)

        groups.each do |type, items|
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

    def fetch_eod
      symbol = "MCD"

      ["US", "NYSE"].each do |exchange|
        symbol_with_exchange = "#{symbol}.#{exchange}"
        relative_path = Path.eod_data(exchange, symbol)

        unless file_stale?(relative_path)
          @log.info("Skipping EOD (fresh): #{relative_path}")
          return
        end

        begin
          @log.info("Fetching EOD JSON: #{symbol_with_exchange}...")
          json = @api.get_eod_data_json!(exchange, symbol)
          saved_path = @io.save_json!(relative_path, json, true)
          @log.info("Wrote #{saved_path}")
          return
        rescue StandardError => e
          @log.warn("Failed EOD for #{symbol_with_exchange}: #{e.class}: #{e.message}")
        ensure
          pause_between_requests
        end
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
