# frozen_string_literal: true

require_relative "eod/run"
require_relative "intraday/intraday_process_strategy"

module Eodhd
  module Commands
    module Process
      class Run
        def initialize(container:)
          @log = container.logger
          @cfg = container.config
          @io = container.io
          @eod_strategy = Eod::Run.new(log: @log, io: @io)
          @intraday_strategy = IntradayProcessStrategy.new(log: @log, io: @io)
        end

        def process_eod
          @eod_strategy.process
        end

        def process_intraday
          @intraday_strategy.process
        end
      end
    end
  end
end
