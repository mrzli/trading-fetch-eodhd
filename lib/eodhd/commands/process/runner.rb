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
          @meta_runner = Subcommands::Meta::Runner.new(log: @log, io: @io)
        end

        def eod(force:, parallel:, workers:)
          @eod_runner.process(force: force, parallel: parallel, workers: workers)
        end

        def intraday(force:, parallel:, workers:)
          @intraday_runner.process(force: force, parallel: parallel, workers: workers)
        end

        def meta(parallel:, workers:)
          @meta_runner.process(parallel: parallel, workers: workers)
        end
      end
    end
  end
end
