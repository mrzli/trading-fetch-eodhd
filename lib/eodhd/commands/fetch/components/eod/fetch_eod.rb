# frozen_string_literal: true

require_relative "../../../../../util"
require_relative "../../../../shared/path"

module Eodhd
  class FetchEod

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

      fetch_eod_for_symbols(filtered_entries, force: force, parallel: parallel, workers: workers)
    end

    private

    def fetch_eod_for_symbols(symbol_entries, force:, parallel:, workers:)
      Util::ParallelExecutor.execute(symbol_entries, parallel: parallel, workers: workers) do |entry|
        fetch_single(entry, force: force)
      end
    end

    def fetch_single(symbol_entry, force:)
      exchange = symbol_entry[:exchange]
      type = symbol_entry[:type]
      symbol = symbol_entry[:symbol]

      symbol_with_exchange = "#{symbol}.#{exchange}"
      relative_path = Shared::Path.raw_eod_data(exchange, symbol)

      unless force || @shared.file_stale?(relative_path)
        @log.info("Skipping EOD (fresh): #{relative_path}")
        return
      end

      begin
        @log.info("Fetching EOD CSV: #{symbol_with_exchange} (#{type})#{force ? ' (forced)' : ''}...")
        csv = @api.get_eod_data_csv(exchange, symbol)
        saved_path = @io.write_csv(relative_path, csv)
        @log.info("Wrote #{StringUtil.truncate_middle(saved_path)}")
      rescue StandardError => e
        @log.warn("Failed EOD for #{symbol_with_exchange}: #{e.class}: #{e.message}")
      end
    end

  end
end
