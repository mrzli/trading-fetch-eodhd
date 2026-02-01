# frozen_string_literal: true

require "json"

require_relative "../../util"
require_relative "../fetch/args"
require_relative "../fetch/fetch_strategy"
require_relative "../shared/container"

module Eodhd
  module Fetch
    module_function

    def run
      container = Container.new(command: "fetch")
      strategy = FetchStrategy.new(container: container)
      args_parser = FetchArgs.new(container: container)

      subcommand, force, recheck_start_date, parallel, workers = args_parser.parse(ARGV).deconstruct

      case subcommand
      when "exchanges"
        strategy.run_exchanges(force: force)
      when "symbols"
        strategy.run_symbols(force: force, parallel: parallel, workers: workers)
      when "meta"
        strategy.run_meta(force: force, parallel: parallel, workers: workers)
      when "eod"
        strategy.run_eod(force: force, parallel: parallel, workers: workers)
      when "intraday"
        strategy.run_intraday(recheck_start_date: recheck_start_date, parallel: parallel, workers: workers)
      else
      end
    end
  end
end
