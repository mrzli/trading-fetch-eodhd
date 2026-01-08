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

    def process_eod
      @eod_strategy.process
    end

    def process_intraday
      @intraday_strategy.process
    end
  end
end
