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
          valid_subcommands: %w[exchanges symbols]
        )

        subcommand, = clean_args_parser.parse(ARGV).deconstruct

        case subcommand
        when "exchanges"
          args_parser = Args.new
          yes, = args_parser.parse(ARGV).deconstruct
          runner.exchanges(yes: yes)
        when "symbols"
          args_parser = Args.new
          yes, = args_parser.parse(ARGV).deconstruct
          runner.symbols(yes: yes)
        else
          raise "Unknown subcommand: #{subcommand}"
        end
      end
    end
  end
end
