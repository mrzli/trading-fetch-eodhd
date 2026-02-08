# frozen_string_literal: true

require "json"

module Eodhd
  module Commands
    module Fetch
      module_function

      def run
        container = Eodhd::Shared::Container.new(command: "fetch")
        strategy = Run.new(container: container)
        fetch_args_parser = Eodhd::Args::SubcommandsArgs.new(
          container: container,
          command_name: "fetch",
          valid_subcommands: %w[exchanges symbols meta eod intraday]
        )

        subcommand, = fetch_args_parser.parse(ARGV).deconstruct

        case subcommand
        when "exchanges"
          args_parser = Subcommands::Exchanges::Args.new(container: container)
          force, = args_parser.parse(ARGV).deconstruct
          strategy.run_exchanges(force: force)
        when "symbols"
          args_parser = Subcommands::Symbols::Args.new(container: container)
          force, parallel, workers = args_parser.parse(ARGV).deconstruct
          strategy.run_symbols(force: force, parallel: parallel, workers: workers)
        when "meta"
          args_parser = Subcommands::Meta::Args.new(container: container)
          force, parallel, workers = args_parser.parse(ARGV).deconstruct
          strategy.run_meta(force: force, parallel: parallel, workers: workers)
        when "eod"
          args_parser = Subcommands::Eod::Args.new(container: container)
          force, parallel, workers = args_parser.parse(ARGV).deconstruct
          strategy.run_eod(force: force, parallel: parallel, workers: workers)
        when "intraday"
          args_parser = Subcommands::Intraday::Args.new(container: container)
          recheck_start_date, parallel, workers = args_parser.parse(ARGV).deconstruct
          strategy.run_intraday(recheck_start_date: recheck_start_date, parallel: parallel, workers: workers)
        else
          raise "Unknown subcommand: #{subcommand}"
        end
      end
    end
  end
end
