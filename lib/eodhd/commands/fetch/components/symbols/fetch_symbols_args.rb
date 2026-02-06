# frozen_string_literal: true

require "optparse"
require_relative "../../../../shared/args"
require_relative "../../args/shared"

module Eodhd
  class FetchSymbolsArgs
    Result = Data.define(:force, :parallel, :workers)

    def initialize(container:)
      @cfg = container.config
    end

    def parse(argv)
      Shared::Args.with_exception_handling { parse_args(argv) }
    end

    private

    def parse_args(argv)
      force = false
      parallel = false
      workers = @cfg.default_workers

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: bin/fetch symbols [options]"

        FetchArgsShared.add_force_option(opts) { |v| force = v }
        FetchArgsShared.add_parallel_option(opts) { |v| parallel = v }
        FetchArgsShared.add_workers_option(opts, @cfg.default_workers) { |v| workers = v }
        FetchArgsShared.add_help_option(opts)
      end

      FetchArgsShared.handle_parse_error(parser) do
        parser.parse!(argv)
        FetchArgsShared.check_args(argv, parser)
        Result.new(force: force, parallel: parallel, workers: workers)
      end
    end
  end
end
