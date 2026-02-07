# frozen_string_literal: true

require "json"

require_relative "../../util"
require_relative "fetch/args/args"
require_relative "fetch/strategy"
require_relative "fetch/components/exchanges/args"
require_relative "fetch/components/symbols/args"
require_relative "fetch/components/meta/args"
require_relative "fetch/components/eod/args"
require_relative "fetch/components/intraday/fetch_intraday_args"
require_relative "../shared/container"

module Eodhd
  module Commands
    module Fetch
      module_function

      def run
        container = ::Eodhd::Shared::Container.new(command: "fetch")
        strategy = Strategy.new(container: container)
        fetch_args_parser = Args::Args.new(container: container)

        subcommand, = fetch_args_parser.parse(ARGV).deconstruct

        case subcommand
        when "exchanges"
          args_parser = Components::Exchanges::Args.new(container: container)
          force, = args_parser.parse(ARGV).deconstruct
          strategy.run_exchanges(force: force)
        when "symbols"
          args_parser = Components::Symbols::Args.new(container: container)
          force, parallel, workers = args_parser.parse(ARGV).deconstruct
          strategy.run_symbols(force: force, parallel: parallel, workers: workers)
        when "meta"
          args_parser = Components::Meta::Args.new(container: container)
          force, parallel, workers = args_parser.parse(ARGV).deconstruct
          strategy.run_meta(force: force, parallel: parallel, workers: workers)
        when "eod"
          args_parser = Components::Eod::Args.new(container: container)
          force, parallel, workers = args_parser.parse(ARGV).deconstruct
          strategy.run_eod(force: force, parallel: parallel, workers: workers)
        when "intraday"
          args_parser = FetchIntradayArgs.new(container: container)
          recheck_start_date, parallel, workers = args_parser.parse(ARGV).deconstruct
          strategy.run_intraday(recheck_start_date: recheck_start_date, parallel: parallel, workers: workers)
        else
          raise "Unknown subcommand: #{subcommand}"
        end
      end
    end
  end
end
