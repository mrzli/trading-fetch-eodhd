# frozen_string_literal: true

require "json"

require_relative "../../util"
require_relative "../fetch/fetch_strategy"
require_relative "../fetch/components/exchanges/fetch_exchanges_args"
require_relative "../fetch/components/symbols/fetch_symbols_args"
require_relative "../fetch/components/meta/fetch_meta_args"
require_relative "../fetch/components/eod/fetch_eod_args"
require_relative "../fetch/components/intraday/fetch_intraday_args"
require_relative "../shared/container"

module Eodhd
  module Fetch
    module_function

    def run
      container = Container.new(command: "fetch")
      strategy = FetchStrategy.new(container: container)

      if ARGV.empty?
        puts "Usage: bin/fetch SUBCOMMAND [options]"
        puts "\nSubcommands: exchanges, symbols, meta, eod, intraday"
        exit 1
      end

      subcommand = ARGV.shift.to_s.strip.downcase

      case subcommand
      when "exchanges"
        args_parser = FetchExchangesArgs.new(container: container)
        force = args_parser.parse(ARGV).deconstruct
        strategy.run_exchanges(force: force)
      when "symbols"
        args_parser = FetchSymbolsArgs.new(container: container)
        force, parallel, workers = args_parser.parse(ARGV).deconstruct
        strategy.run_symbols(force: force, parallel: parallel, workers: workers)
      when "meta"
        args_parser = FetchMetaArgs.new(container: container)
        force, parallel, workers = args_parser.parse(ARGV).deconstruct
        strategy.run_meta(force: force, parallel: parallel, workers: workers)
      when "eod"
        args_parser = FetchEodArgs.new(container: container)
        force, parallel, workers = args_parser.parse(ARGV).deconstruct
        strategy.run_eod(force: force, parallel: parallel, workers: workers)
      when "intraday"
        args_parser = FetchIntradayArgs.new(container: container)
        recheck_start_date, parallel, workers = args_parser.parse(ARGV).deconstruct
        strategy.run_intraday(recheck_start_date: recheck_start_date, parallel: parallel, workers: workers)
      else
        puts "Unknown subcommand: #{subcommand}"
        puts "Valid subcommands: exchanges, symbols, meta, eod, intraday"
        exit 1
      end
    end
  end
end
