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

          @exchanges_runner = Subcommands::Exchanges::Runner.new(container: container, shared: shared)
          @symbols_runner = Subcommands::Symbols::Runner.new(container: container, shared: shared)
          @meta_runner = Subcommands::Meta::Runner.new(container: container, shared: shared)
          @eod_runner = Subcommands::Eod::Runner.new(container: container, shared: shared)
          @intraday_runner = Subcommands::Intraday::Runner.new(container: container, shared: shared)

          @data_reader = container.data_reader
        end

        def exchanges(force:)
          @exchanges_runner.fetch(force: force)
        end

        def symbols(force:, parallel:, workers:)
          @symbols_runner.fetch(force: force, parallel: parallel, workers: workers)
        end

        def meta(force:, parallel:, workers:)
          @meta_runner.fetch(force: force, parallel: parallel, workers: workers)
        end

        def eod(force:, parallel:, workers:)
          @eod_runner.fetch(force: force, parallel: parallel, workers: workers)
        end

        def intraday(recheck_start_date:, unfetched_only:, parallel:, workers:)
          @intraday_runner.fetch(
            recheck_start_date: recheck_start_date,
            unfetched_only: unfetched_only,
            parallel: parallel,
            workers: workers
          )
        end

      end
    end
  end
end
