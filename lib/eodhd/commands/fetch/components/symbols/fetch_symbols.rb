# frozen_string_literal: true

require "json"

require_relative "../../../../../util"
require_relative "../../../../shared/path"

module Eodhd
  class FetchSymbols
    def initialize(container:, shared:)
      @log = container.logger
      @api = container.api
      @io = container.io
      @data_reader = container.data_reader

      @shared = shared
    end

    def fetch(force:, parallel:, workers:)
      exchanges = @data_reader.exchanges
      exchange_items = build_exchange_items(exchanges)

      fetch_symbols_for_exchanges(exchange_items, force: force, parallel: parallel, workers: workers)
    end

    private

    def fetch_symbols_for_exchanges(exchange_items, force:, parallel:, workers:)
      Util::ParallelExecutor.execute(exchange_items, parallel: parallel, workers: workers) do |item|
        fetch_symbols_for_exchange(item[:exchange], force: force, existing_paths: item[:existing_paths])
      end
    end

    def build_exchange_items(exchanges)
      exchanges.map do |exchange|
        { exchange: exchange, existing_paths: symbols_paths_for_exchange(exchange) }
      end
    end

    def fetch_symbols_for_exchange(exchange, force:, existing_paths:)
      if !force && existing_paths.any? && existing_paths.none? { |path| @shared.file_stale?(path) }
        @log.info("Skipping symbols (fresh): #{File.join('symbols', Util::String.kebab_case(exchange), '*.json')}")
        return
      end

      @log.info("Fetching symbols for #{exchange}#{force ? ' (forced)' : ''}...")

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
          saved_path = @io.write_json(relative_path, JSON.generate(items), true)
          @log.info("Wrote #{StringUtil.truncate_middle(saved_path)}")
        end
      rescue StandardError => e
        @log.warn("Failed symbols for #{exchange}: #{e.class}: #{e.message}")
      end
    end

    def symbols_paths_for_exchange(exchange)
      relative_dir = File.join("symbols", Util::String.kebab_case(exchange))

      @io
        .list_relative_files(relative_dir)
        .select { |path| path.end_with?(".json") }
    end

  end
end
