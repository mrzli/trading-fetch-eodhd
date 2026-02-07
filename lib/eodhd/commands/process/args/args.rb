# frozen_string_literal: true

require "optparse"

module Eodhd
  module Commands
    module Process
      module Args
        class Args
          Result = Data.define(:subcommand)

          VALID_SUBCOMMANDS = %w[eod intraday].freeze

          def initialize(container:)
            @cfg = container.config
          end

          def parse(argv)
            Eodhd::Shared::Args.with_exception_handling { parse_args(argv) }
          end

          private

          def parse_args(argv)
            parser = OptionParser.new do |opts|
              opts.banner = "Usage: bin/process SUBCOMMAND [options]\n\nSubcommands: #{VALID_SUBCOMMANDS.join(', ')}"
              Shared.add_help_option(opts)
            end

            Shared.handle_parse_error(parser) do
              if argv.empty?
                raise Shared::Args::Error.new("Missing required subcommand.", usage: parser.to_s)
              end

              potential_subcommand = argv.first.to_s.strip.downcase
              if VALID_SUBCOMMANDS.include?(potential_subcommand)
                subcommand = argv.shift.to_s.strip.downcase
                Result.new(subcommand: subcommand)
              else
                parser.parse!(argv)

                if argv.empty?
                  raise Shared::Args::Error.new("Missing required subcommand.", usage: parser.to_s)
                end

                subcommand = argv.shift.to_s.strip.downcase
                unless VALID_SUBCOMMANDS.include?(subcommand)
                  raise Shared::Args::Error.new("Unknown subcommand: #{subcommand.inspect}. Expected one of: #{VALID_SUBCOMMANDS.join(', ')}.", usage: parser.to_s)
                end

                Result.new(subcommand: subcommand)
              end
            end
          end
        end
      end
    end
  end
end
