# frozen_string_literal: true

module Eodhd
  module Commands
    module Clean
      module_function

      def run
        container = Eodhd::Shared::Container.new(command: "clean")
        runner = Runner.new(container: container)
        clean_args_parser = Eodhd::Args::SubcommandsArgs.new(
          container: container,
          command_name: "clean",
          valid_subcommands: %w[exchanges symbols meta raw raw-eod raw-intraday data data-eod data-intraday log]
        )

        subcommand, = clean_args_parser.parse(ARGV).deconstruct
        args_parser = Args.new
        yes, dry_run = args_parser.parse(ARGV).deconstruct

        case subcommand
        when "exchanges"
          runner.exchanges(yes: yes, dry_run: dry_run)
        when "symbols"
          runner.symbols(yes: yes, dry_run: dry_run)
        when "meta"
          runner.meta(yes: yes, dry_run: dry_run)
        when "raw"
          runner.raw(yes: yes, dry_run: dry_run)
        when "raw-eod"
          runner.raw_eod(yes: yes, dry_run: dry_run)
        when "raw-intraday"
          runner.raw_intraday(yes: yes, dry_run: dry_run)
        when "data"
          runner.data(yes: yes, dry_run: dry_run)
        when "data-eod"
          runner.data_eod(yes: yes, dry_run: dry_run)
        when "data-intraday"
          runner.data_intraday(yes: yes, dry_run: dry_run)
        when "log"
          runner.log(yes: yes, dry_run: dry_run)
        else
          raise "Unknown subcommand: #{subcommand}"
        end
      end
    end
  end
end
