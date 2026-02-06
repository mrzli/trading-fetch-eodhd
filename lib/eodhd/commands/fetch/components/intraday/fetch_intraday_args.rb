# frozen_string_literal: true

require "optparse"
require_relative "../../../../shared/args"
require_relative "../../args/shared"

module Eodhd
  class FetchIntradayArgs
    Result = Data.define(:recheck_start_date, :parallel, :workers)

    def initialize(container:)
      @cfg = container.config
    end

    def parse(argv)
      Shared::Args.with_exception_handling { parse_args(argv) }
    end

    private

    def parse_args(argv)
      recheck_start_date = false
      parallel = false
      workers = @cfg.default_workers

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: bin/fetch intraday [options]"

        FetchArgsShared.add_recheck_start_date_option(opts) { |v| recheck_start_date = v }
        FetchArgsShared.add_parallel_option(opts) { |v| parallel = v }
        FetchArgsShared.add_workers_option(opts, @cfg.default_workers) { |v| workers = v }
        FetchArgsShared.add_help_option(opts)
      end

      FetchArgsShared.handle_parse_error(parser) do
        parser.parse!(argv)
        FetchArgsShared.check_args(argv, parser)
        Result.new(recheck_start_date: recheck_start_date, parallel: parallel, workers: workers)
      end
    end
  end
end
