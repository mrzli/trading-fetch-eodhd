# frozen_string_literal: true

require "json"
require "set"
require "time"

require_relative "../../util"
require_relative "../shared/path"
require_relative "shared"
require_relative "fetch_exchange_data"
require_relative "fetch_splits"
require_relative "fetch_dividends"
require_relative "fetch_eod"
require_relative "fetch_intraday"

module Eodhd
  class FetchStrategy

    def initialize(log:, cfg:, api:, io:)
      @log = log
      @cfg = cfg
      @api = api
      @io = io
      @shared = FetchShared.new(cfg: cfg, io: io)
      @fetch_exchange_data = FetchExchangeData.new(log: log, api: api, io: io, shared: @shared)
      @fetch_splits = FetchSplits.new(log: log, api: api, io: io, shared: @shared)
      @fetch_dividends = FetchDividends.new(log: log, api: api, io: io, shared: @shared)
      @fetch_eod = FetchEod.new(log: log, api: api, io: io, shared: @shared)
      @fetch_intraday = FetchIntraday.new(log: log, api: api, io: io, shared: @shared)
    end
∏
    def run
      symbol_entries = @fetch_exchange_data.fetch

      @fetch_splits.fetch(symbol_entries)
      @fetch_dividends.fetch(symbol_entries)
      @fetch_eod.fetch(symbol_entries)
      @fetch_intraday.fetch(symbol_entries)
    end

    private

  end
end
