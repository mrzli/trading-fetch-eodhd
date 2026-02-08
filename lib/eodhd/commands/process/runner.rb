# frozen_string_literal: true

module Eodhd
  module Commands
    module Process
      class Runner
        def initialize(container:)
          @log = container.logger
          @cfg = container.config
          @io = container.io
          @eod_strategy = Subcommands::Eod::Runner.new(log: @log, io: @io)
          @intraday_strategy = Subcommands::Intraday::Runner.new(log: @log, io: @io)
        end

        def eod
          @eod_strategy.process
        end

        def intraday
          @intraday_strategy.process
        end
      end
    end
  end
end
