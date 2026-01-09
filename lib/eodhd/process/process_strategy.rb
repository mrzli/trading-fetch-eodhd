# frozen_string_literal: true

require_relative "eod/eod_process_strategy"
require_relative "intraday/intraday_process_strategy"

module Eodhd
  class ProcessStrategy
    def initialize(log:, cfg:, io:)
      @log = log
      @cfg = cfg
      @io = io
      @eod_strategy = EodProcessStrategy.new(log: log, io: io)
      @intraday_strategy = IntradayProcessStrategy.new(log: log, io: io)
    end

    def process_eod(exchange_filters:, symbol_filters:)
      @eod_strategy.process(exchange_filters: exchange_filters, symbol_filters: symbol_filters)
    end

    def process_intraday(exchange_filters:, symbol_filters:)
      @intraday_strategy.process(exchange_filters: exchange_filters, symbol_filters: symbol_filters)
    end
  end
end
