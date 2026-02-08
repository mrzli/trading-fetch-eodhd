# frozen_string_literal: true

require "json"

module Eodhd
  module Commands
    module Process
      module_function

      def run
        container = Eodhd::Shared::Container.new(command: "process")
        runner = Runner.new(container: container)
        process_args_parser = Eodhd::Args::SubcommandsArgs.new(
          container: container,
          command_name: "process",
          valid_subcommands: %w[eod intraday]
        )

        subcommand, = process_args_parser.parse(ARGV).deconstruct

        case subcommand
        when "eod"
          args_parser = Subcommands::Eod::Args.new(container: container)
          args_parser.parse(ARGV)
          runner.process_eod
        when "intraday"
          args_parser = Subcommands::Intraday::Args.new(container: container)
          args_parser.parse(ARGV)
          runner.process_intraday
        else
          raise "Unknown subcommand: #{subcommand}"
        end
      end
    end
  end
end
