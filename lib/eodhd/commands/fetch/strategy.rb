# frozen_string_literal: true

require "json"
require "set"
require "time"

require_relative "../../../util"
require_relative "../../shared/path"
require_relative "shared"
require_relative "subcommands/exchanges/exchanges"
require_relative "subcommands/symbols/symbols"
require_relative "subcommands/meta/meta"
require_relative "subcommands/eod/eod"
require_relative "subcommands/intraday/intraday"

module Eodhd
  module Commands
    module Fetch
      class Strategy
        INTRADAY_INCLUDED_EXCHANGES = Set.new(["US"]).freeze
        INTRADAY_INCLUDED_SYMBOLS = Set.new(["AAPL"]).freeze

        def initialize(container:)
          shared = Shared.new(container: container)

          @fetch_exchanges = Subcommands::Exchanges::Exchanges.new(container: container, shared: shared)
          @fetch_symbols = Subcommands::Symbols::Symbols.new(container: container, shared: shared)
          @fetch_meta = Subcommands::Meta::Meta.new(container: container, shared: shared)
          @fetch_eod = Subcommands::Eod::Eod.new(container: container, shared: shared)
          @fetch_intraday = Subcommands::Intraday::Intraday.new(container: container, shared: shared)

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
end
