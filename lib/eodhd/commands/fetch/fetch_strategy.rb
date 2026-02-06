# frozen_string_literal: true

require "json"
require "set"
require "time"

require_relative "../../../util"
require_relative "../../shared/path"
require_relative "shared"
require_relative "components/exchanges/fetch_exchanges"
require_relative "components/symbols/fetch_symbols"
require_relative "components/meta/fetch_meta"
require_relative "components/eod/fetch_eod"
require_relative "components/intraday/fetch_intraday"

module Eodhd
  module Commands
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

      def run_intraday(recheck_start_date:, parallel:, workers:)
        @fetch_intraday.fetch(recheck_start_date: recheck_start_date, parallel: parallel, workers: workers)
      end

    end
  end
end
