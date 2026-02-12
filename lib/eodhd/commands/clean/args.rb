# frozen_string_literal: true

require "optparse"

module Eodhd
  module Commands
    module Clean
      class Args
        Result = Data.define(:yes, :dry_run)

        def parse(argv)
          Eodhd::Shared::Args.with_exception_handling { parse_args(argv) }
        end

        private

        def parse_args(argv)
          yes = false
          dry_run = false

          parser = OptionParser.new do |opts|
            opts.banner = "Usage: bin/clean COMMAND [options]"
            Eodhd::Args::Shared.add_yes_option(opts) { |v| yes = v }
            Eodhd::Args::Shared.add_dry_run_option(opts) { |v| dry_run = v }
            Eodhd::Args::Shared.add_help_option(opts)
          end

          Eodhd::Args::Shared.handle_parse_error(parser) do
            parser.parse!(argv)
            Eodhd::Args::Shared.check_args(argv, parser)
            Result.new(yes: yes, dry_run: dry_run)
          end
        end
      end
    end
  end
end
