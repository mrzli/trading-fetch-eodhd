# frozen_string_literal: true

require "json"

require_relative "../../../util"
require_relative "../../shared/path"

module Eodhd
  class FetchExchanges
    def initialize(log:, api:, io:, shared:)
      @log = log
      @api = api
      @io = io
      @shared = shared
    end

    def fetch
      relative_path = Path.exchanges_list

      if @shared.file_stale?(relative_path)
        @log.info("Fetching exchanges list...")
        fetched = @api.get_exchanges_list_json
        saved_path = @io.write_json(relative_path, fetched, true)
        @log.info("Wrote #{saved_path}")
      else
        @log.info("Skipping exchanges list (fresh): #{relative_path}.")
      end
    end

  end
end
