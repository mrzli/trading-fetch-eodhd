# frozen_string_literal: true

require "json"
require "set"
require "time"

module Eodhd
  module Commands
    module Fetch
      class Runner
        INTRADAY_INCLUDED_EXCHANGES = Set.new(["US"]).freeze
        INTRADAY_INCLUDED_SYMBOLS = Set.new(["AAPL"]).freeze

        def initialize(container:)
          shared = Shared.new(container: container)

          @fetch_exchanges = Subcommands::Exchanges::Runner.new(container: container, shared: shared)
          @fetch_symbols = Subcommands::Symbols::Runner.new(container: container, shared: shared)
          @fetch_meta = Subcommands::Meta::Runner.new(container: container, shared: shared)
          @fetch_eod = Subcommands::Eod::Runner.new(container: container, shared: shared)
          @fetch_intraday = Subcommands::Intraday::Runner.new(container: container, shared: shared)

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
