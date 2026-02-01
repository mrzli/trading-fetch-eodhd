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
require_relative "components/intraday/fetch_intraday"

module Eodhd
  class FetchStrategy
    INTRADAY_INCLUDED_EXCHANGES = Set.new(["US"]).freeze
    INTRADAY_INCLUDED_SYMBOLS = Set.new(["AAPL"]).freeze

    def initialize(container:)
      shared = FetchShared.new(container: container)
      @fetch_exchanges = FetchExchanges.new(container: container, shared: shared)
      @fetch_symbols = FetchSymbols.new(container: container, shared: shared)
      @fetch_meta = FetchMeta.new(container: container, shared: shared)
      @fetch_eod = FetchEod.new(container: container, shared: shared)
      @fetch_intraday = FetchIntraday.new(container: container, shared: shared)

      @data_reader = container.data_reader
    end

    def run_exchanges(force:)
      @fetch_exchanges.fetch(force: force)
    end

    def run_symbols(force:, parallel:, workers:)
      @fetch_symbols.fetch(force: force, parallel: parallel, workers: workers)
    end

    def run_meta(force:, parallel:, workers:)
      @fetch_meta.fetch(force: force, parallel: parallel, workers: workers)
    end

    def run_eod(force:, parallel:, workers:)
      @fetch_eod.fetch(force: force, parallel: parallel, workers: workers)
    end

    def run_rest
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
