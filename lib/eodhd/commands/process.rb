# frozen_string_literal: true

require "json"

require_relative "../../util"
require_relative "process/args/process_args"
require_relative "process/process_strategy"
require_relative "process/eod/process_eod_args"
require_relative "process/intraday/process_intraday_args"
require_relative "../shared/container"

module Eodhd
  module Process
    module_function

    def run
      container = Shared::Container.new(command: "process")
      strategy = ProcessStrategy.new(container: container)
      process_args_parser = ProcessArgs.new(container: container)

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
