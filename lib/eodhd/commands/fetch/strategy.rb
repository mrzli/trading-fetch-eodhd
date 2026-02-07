# frozen_string_literal: true

require "json"
require "set"
require "time"

require_relative "../../../util"
require_relative "../../shared/path"
require_relative "shared"
require_relative "subcommands/exchanges/run"
require_relative "subcommands/symbols/run"
require_relative "subcommands/meta/run"
require_relative "subcommands/eod/run"
require_relative "subcommands/intraday/run"

module Eodhd
  module Commands
    module Fetch
      class Strategy
        INTRADAY_INCLUDED_EXCHANGES = Set.new(["US"]).freeze
        INTRADAY_INCLUDED_SYMBOLS = Set.new(["AAPL"]).freeze

        def initialize(container:)
          shared = Shared.new(container: container)

          @fetch_exchanges = Subcommands::Exchanges::Run.new(container: container, shared: shared)
          @fetch_symbols = Subcommands::Symbols::Run.new(container: container, shared: shared)
          @fetch_meta = Subcommands::Meta::Run.new(container: container, shared: shared)
          @fetch_eod = Subcommands::Eod::Run.new(container: container, shared: shared)
          @fetch_intraday = Subcommands::Intraday::Run.new(container: container, shared: shared)

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
