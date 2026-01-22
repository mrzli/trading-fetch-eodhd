# frozen_string_literal: true

require "json"

require_relative "../../util"
require_relative "../process/args"
require_relative "../process/process_strategy"
require_relative "../shared/container"

module Eodhd
  module Process
    module_function

    def run()
      mode, exchange_filters, symbol_filters = ProcessArgs.parse(ARGV)
      container = Container.new(command: "process")

      strategy = ProcessStrategy.new(
        log: container.logger,
        cfg: container.config,
        io: container.io
      )

      puts mode

      # case mode
      # when "eod"
      #   strategy.process_eod(exchange_filters: exchange_filters, symbol_filters: symbol_filters)
      # when "intraday"
      #   strategy.process_intraday(exchange_filters: exchange_filters, symbol_filters: symbol_filters)
      # end
    end
  end
end
