# frozen_string_literal: true

require "optparse"

module Eodhd
  module Commands
    module Process
      module Subcommands
        module Meta
          class Args
            Result = Data.define

            def initialize(container:); end

            def parse(argv)
              Eodhd::Shared::Args.with_exception_handling { parse_args(argv) }
            end

            private

            def parse_args(argv)
              parser = OptionParser.new do |opts|
                opts.banner = "Usage: bin/process meta [options]"
                Eodhd::Args::Shared.add_help_option(opts)
              end

              Eodhd::Args::Shared.handle_parse_error(parser) do
                parser.parse!(argv)
                Eodhd::Args::Shared.check_args(argv, parser)
                Result.new
              end
            end
          end
        end
      end
    end
  end
end
