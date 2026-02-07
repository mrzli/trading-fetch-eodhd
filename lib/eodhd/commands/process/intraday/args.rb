# frozen_string_literal: true

require "optparse"

module Eodhd
  module Commands
    module Process
      module Intraday
        class Args
          Result = Data.define

          def initialize(container:)
            @cfg = container.config
          end

          def parse(argv)
            Shared::Args.with_exception_handling { parse_args(argv) }
          end

          private

          def parse_args(argv)
            parser = OptionParser.new do |opts|
              opts.banner = "Usage: bin/process intraday [options]"
              Args::Shared.add_help_option(opts)
            end

            Args::Shared.handle_parse_error(parser) do
              parser.parse!(argv)
              Args::Shared.check_args(argv, parser)
              Result.new
            end
          end
        end
      end
    end
  end
end
