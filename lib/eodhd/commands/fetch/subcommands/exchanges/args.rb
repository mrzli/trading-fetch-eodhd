# frozen_string_literal: true

require "optparse"

module Eodhd
  module Commands
    module Fetch
      module Subcommands
        module Exchanges
          class Args
            Result = Data.define(:force)

            def initialize(container:)
              @cfg = container.config
            end

            def parse(argv)
              Eodhd::Shared::Args.with_exception_handling { parse_args(argv) }
            end

            private

            def parse_args(argv)
              force = false

              parser = OptionParser.new do |opts|
                opts.banner = "Usage: bin/fetch exchanges [options]"

                Args::Shared.add_force_option(opts) { |v| force = v }
                Args::Shared.add_help_option(opts)
              end

              Args::Shared.handle_parse_error(parser) do
                parser.parse!(argv)
                Args::Shared.check_args(argv, parser)
                Result.new(force: force)
              end
            end
          end
        end
      end
    end
  end
end
