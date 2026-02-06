# frozen_string_literal: true

require "optparse"
require_relative "../../shared/args"
require_relative "../args/shared"

module Eodhd
  class ProcessEodArgs
    Result = Data.define

    def initialize(container:)
      @cfg = container.config
    end

    def parse(argv)
      Args.with_exception_handling { parse_args(argv) }
    end

    private

    def parse_args(argv)
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: bin/process eod [options]"
        ProcessArgsShared.add_help_option(opts)
      end

      ProcessArgsShared.handle_parse_error(parser) do
        parser.parse!(argv)
        ProcessArgsShared.check_args(argv, parser)
        Result.new
      end
    end
  end
end
