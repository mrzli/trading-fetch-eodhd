# frozen_string_literal: true

require "json"


module Eodhd
  module Commands
    module Process
      module_function

      def run
        container = Eodhd::Shared::Container.new(command: "process")
        strategy = Run.new(container: container)
        process_args_parser = Args::Args.new(container: container)

        subcommand, = process_args_parser.parse(ARGV).deconstruct

        case subcommand
        when "eod"
          args_parser = Eod::Args.new(container: container)
          args_parser.parse(ARGV)
          strategy.process_eod
        when "intraday"
          args_parser = Intraday::Args.new(container: container)
          args_parser.parse(ARGV)
          strategy.process_intraday
        else
          raise "Unknown subcommand: #{subcommand}"
        end
      end
    end
  end
end
