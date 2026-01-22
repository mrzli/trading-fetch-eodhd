# frozen_string_literal: true

require "json"
require "set"
require "time"

require_relative "../../util"
require_relative "../shared/path"
require_relative "shared"
require_relative "components/fetch_exchanges"
require_relative "components/fetch_symbols"
require_relative "components/fetch_meta"
require_relative "components/fetch_eod"
require_relative "components/fetch_intraday"

module Eodhd
  class FetchStrategy
    INTRADAY_INCLUDED_EXCHANGES = Set.new(["US"]).freeze
    INTRADAY_INCLUDED_SYMBOLS = Set.new(["AAPL"]).freeze

    def initialize(log:, cfg:, api:, io:)
      @log = log
      @cfg = cfg
      @api = api
      @io = io
      @shared = FetchShared.new(cfg: cfg, io: io)
      @fetch_exchanges = FetchExchanges.new(log: log, api: api, io: io, shared: @shared)
      @fetch_symbols = FetchSymbols.new(log: log, api: api, io: io, shared: @shared)
      @fetch_meta = FetchMeta.new(log: log, api: api, io: io, shared: @shared)
      @fetch_eod = FetchEod.new(log: log, api: api, io: io, shared: @shared)
      @fetch_intraday = FetchIntraday.new(log: log, api: api, io: io, shared: @shared)
    end

    def run_all
      run_exchanges
      run_symbols
      run_rest
    end

    def run_exchanges
      @fetch_exchanges.fetch
    end

    def run_symbols
      # exchanges = @fetch_exchanges.fetch
    end

    def run_rest
      # exchanges = @fetch_exchanges.fetch
      # symbol_entries = @fetch_symbols.fetch(exchanges)

      # @fetch_meta.fetch(symbol_entries)

      # @fetch_eod.fetch(symbol_entries)

      # intraday_symbol_entries = symbol_entries.select do |entry|
      #   (INTRADAY_INCLUDED_SYMBOLS.length == 0 || INTRADAY_INCLUDED_SYMBOLS.include?(entry[:symbol]) && INTRADAY_INCLUDED_EXCHANGES.include?(entry[:exchange]))
      # end
      # @fetch_intraday.fetch(intraday_symbol_entries)
    end

    private

  end
end
