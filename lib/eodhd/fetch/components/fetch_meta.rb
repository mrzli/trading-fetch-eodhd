# frozen_string_literal: true

require_relative "../../../util"
require_relative "../../shared/path"

module Eodhd
  class FetchMeta

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
      fetch_metadata(symbol_entry, :splits, ->(e, s) { @api.get_splits_json(e, s) })
      fetch_metadata(symbol_entry, :dividends, ->(e, s) { @api.get_dividends_json(e, s) })
    end

    def fetch_metadata(symbol_entry, type, api_method)
      exchange = symbol_entry[:exchange]
      symbol = symbol_entry[:symbol]
      symbol_with_exchange = "#{symbol}.#{exchange}"

      path = Path.public_send(type, exchange, symbol)
      unless @shared.file_stale?(path)
        @log.info("Skipping #{type} (fresh): #{path}")
        return
      end

      begin
        @log.info("Fetching #{type} JSON: #{symbol_with_exchange}...")
        data = api_method.call(exchange, symbol)
        saved_path = @io.save_json(path, data, true)
        @log.info("Wrote #{saved_path}")
      rescue StandardError => e
        @log.warn("Failed #{type} for #{symbol_with_exchange}: #{e.class}: #{e.message}")
      ensure
        @shared.pause_between_requests
      end
    end

  end
end
