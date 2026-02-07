# frozen_string_literal: true

require "json"

require_relative "../../util"
require_relative "process/args/args"
require_relative "process/run"
require_relative "process/eod/process_eod_args"
require_relative "process/intraday/process_intraday_args"
require_relative "../shared/container"

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
          args_parser = ProcessEodArgs.new(container: container)
          args_parser.parse(ARGV)
          strategy.process_eod
        when "intraday"
          args_parser = ProcessIntradayArgs.new(container: container)
          args_parser.parse(ARGV)
          strategy.process_intraday
        else
          raise "Unknown subcommand: #{subcommand}"
        end
      end
    end
  end
end
