# frozen_string_literal: true

module Eodhd
  module Commands
    module Process
      class Runner
        def initialize(container:)
          @log = container.logger
          @cfg = container.config
          @io = container.io
          @eod_runner = Subcommands::Eod::Runner.new(log: @log, io: @io)
          @intraday_runner = Subcommands::Intraday::Runner.new(log: @log, io: @io)
        end

        def eod
          @eod_runner.process
        end

        def intraday
          @intraday_runner.process
        end
      end
    end
  end
end
