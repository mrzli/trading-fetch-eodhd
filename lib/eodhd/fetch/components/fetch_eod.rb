# frozen_string_literal: true

require_relative "../../../util"
require_relative "../../shared/path"

module Eodhd
  class FetchEod

    def initialize(container:, shared:)
      @log = container.logger
      @api = container.api
      @io = container.io
      @shared = shared
    end

    def fetch(symbol_entries)
      symbol_entries.each do |entry|
        next unless @shared.should_fetch_symbol?(entry)
        fetch_single(entry)
      end
    end

    private

    def fetch_single(symbol_entry)
      exchange = symbol_entry[:exchange]
      type = symbol_entry[:type]
      symbol = symbol_entry[:symbol]

      symbol_with_exchange = "#{symbol}.#{exchange}"
      relative_path = Path.raw_eod_data(exchange, symbol)

      unless @shared.file_stale?(relative_path)
        @log.info("Skipping EOD (fresh): #{relative_path}")
        return
      end

      begin
        @log.info("Fetching EOD CSV: #{symbol_with_exchange} (#{type})...")
        csv = @api.get_eod_data_csv(exchange, symbol)
        saved_path = @io.write_csv(relative_path, csv)
        @log.info("Wrote #{saved_path}")
      rescue StandardError => e
        @log.warn("Failed EOD for #{symbol_with_exchange}: #{e.class}: #{e.message}")
      ensure
        @shared.pause_between_requests
      end
    end

  end
end
