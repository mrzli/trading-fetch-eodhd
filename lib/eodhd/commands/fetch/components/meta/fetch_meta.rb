# frozen_string_literal: true

require_relative "../../../../../util"
require_relative "../../../../shared/path"

module Eodhd
  module Commands
    class FetchMeta

      def initialize(container:, shared:)
        @log = container.logger
        @api = container.api
        @io = container.io
        @data_reader = container.data_reader

        @shared = shared
      end

      def fetch(force:, parallel:, workers:)
        symbol_entries = @data_reader.symbols
        filtered_entries = symbol_entries.filter { |entry| @shared.should_fetch_symbol?(entry) }

        fetch_metadata_for_symbols(filtered_entries, force: force, parallel: parallel, workers: workers)
      end

      private

      def fetch_metadata_for_symbols(symbol_entries, force:, parallel:, workers:)
        Util::ParallelExecutor.execute(symbol_entries, parallel: parallel, workers: workers) do |entry|
          fetch_single(entry, force: force)
        end
      end

      def fetch_single(symbol_entry, force:)
        threads = [
          Thread.new { fetch_metadata(symbol_entry, :splits, ->(e, s) { @api.get_splits_json(e, s) }, force: force) },
          Thread.new { fetch_metadata(symbol_entry, :dividends, ->(e, s) { @api.get_dividends_json(e, s) }, force: force) }
        ]
        threads.each(&:join)
      end

      def fetch_metadata(symbol_entry, type, api_method, force:)
        exchange = symbol_entry[:exchange]
        symbol = symbol_entry[:symbol]
        symbol_with_exchange = "#{symbol}.#{exchange}"

        path = Shared::Path.public_send(type, exchange, symbol)
        unless force || @shared.file_stale?(path)
          @log.info("Skipping #{type} (fresh): #{path}")
          return
        end

        @log.info("Fetching #{type} JSON: #{symbol_with_exchange}#{force ? ' (forced)' : ''}...")
        data = api_method.call(exchange, symbol)
        saved_path = @io.write_json(path, data, true)
        @log.info("Wrote #{StringUtil.truncate_middle(saved_path)}")
      rescue StandardError => e
        @log.warn("Failed #{type} for #{symbol_with_exchange}: #{e.class}: #{e.message}")
      end

    end
  end
end
