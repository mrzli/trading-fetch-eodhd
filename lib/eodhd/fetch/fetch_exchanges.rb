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
      get_exchange_codes
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

  end
end
