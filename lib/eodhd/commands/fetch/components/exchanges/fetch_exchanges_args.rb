# frozen_string_literal: true

require "optparse"
require_relative "../../../../shared/args"
require_relative "../../args/shared"

module Eodhd
  class FetchExchangesArgs
    Result = Data.define(:force)

    def initialize(container:)
      @cfg = container.config
    end

    def parse(argv)
      Args.with_exception_handling { parse_args(argv) }
    end

    private

    def parse_args(argv)
      force = false

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: bin/fetch exchanges [options]"

        FetchArgsShared.add_force_option(opts) { |v| force = v }
        FetchArgsShared.add_help_option(opts)
      end

      FetchArgsShared.handle_parse_error(parser) do
        parser.parse!(argv)
        FetchArgsShared.check_args(argv, parser)
        Result.new(force: force)
      end
    end
  end
end
