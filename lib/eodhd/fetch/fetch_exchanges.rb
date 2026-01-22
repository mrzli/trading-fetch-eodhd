# frozen_string_literal: true

require "json"

require_relative "../../util"
require_relative "../shared/path"

module Eodhd
  class FetchExchanges
    UNSUPPORTED_EXCHANGE_CODES = Set.new(["MONEY"]).freeze

    def initialize(log:, api:, io:, shared:)
      @log = log
      @api = api
      @io = io
      @shared = shared
    end

    def fetch
      fetch_exchanges_list
      exchanges = get_exchange_codes
      fetch_symbols_for_exchanges(exchanges)
      get_symbol_entries(exchanges)
    end

    private

    def fetch_exchanges_list
      relative_path = Path.exchanges_list

      if @shared.file_stale?(relative_path)
        @log.info("Fetching exchanges list...")
        fetched = @api.get_exchanges_list_json
        saved_path = @io.save_json(relative_path, fetched, true)
        @log.info("Wrote #{saved_path}")
      else
        @log.info("Skipping exchanges list (fresh): #{relative_path}.")
      end
    end

    def get_exchange_codes
      exchanges_text = @io.read_text(Path.exchanges_list)
      exchanges = JSON.parse(exchanges_text)
      exchanges.filter_map do |exchange|
        code = exchange["Code"].to_s.strip
        next if UNSUPPORTED_EXCHANGE_CODES.include?(code)
        code
      end
    end

    def fetch_symbols_for_exchanges(exchanges)
      exchanges.each do |exchange|
        fetch_symbols_for_exchange(exchange)
      end
    end

    def fetch_symbols_for_exchange(exchange)
      exchange = Validate.required_string("exchange", exchange)

      existing_paths = symbols_paths_for_exchange(exchange)
      if existing_paths.any? && existing_paths.none? { |path| @shared.file_stale?(path) }
        @log.info("Skipping symbols (fresh): #{File.join('symbols', StringUtil.kebab_case(exchange), '*.json')}")
        return
      end

      begin
        symbols_text = @api.get_exchange_symbol_list_json(exchange)
        symbols = JSON.parse(symbols_text)

        symbols_by_type = symbols.group_by do |symbol|
          raw_type = symbol["Type"]
          type = StringUtil.kebab_case(raw_type)
          type = "unknown" if type.empty?
          type
        end

        symbols_by_type.each do |type, items|
          relative_path = Path.exchange_symbol_list(exchange, type)
          saved_path = @io.save_json(relative_path, JSON.generate(items), true)
          @log.info("Wrote #{saved_path}")
        end
      rescue StandardError => e
        @log.warn("Failed symbols for #{exchange}: #{e.class}: #{e.message}")
      ensure
        @shared.pause_between_requests
      end
    end

    def symbols_paths_for_exchange(exchange)
      relative_dir = File.join("symbols", StringUtil.kebab_case(exchange))

      @io
        .list_relative_paths(relative_dir)
        .select { |path| path.end_with?(".json") }
    end

    def get_symbol_entries(exchanges)
      exchanges.flat_map do |exchange|
        exchange = Validate.required_string("exchange", exchange)

        relative_dir = File.join("symbols", StringUtil.kebab_case(exchange))

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
                exchange: exchange,
                real_exchange: entry["Exchange"],
                type: type,
                symbol: entry["Code"]
              }
            end
          end
      end
    end

  end
end
