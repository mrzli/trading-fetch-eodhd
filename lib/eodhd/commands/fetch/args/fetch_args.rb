# frozen_string_literal: true

require "optparse"
require_relative "../../../shared/args"
require_relative "shared"

module Eodhd
  class FetchArgs
    Result = Data.define(:subcommand)

    VALID_SUBCOMMANDS = %w[exchanges symbols meta eod intraday].freeze

    def initialize(container:)
      @cfg = container.config
    end

    def parse(argv)
      Args.with_exception_handling { parse_args(argv) }
    end

    private

    def parse_args(argv)
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: bin/fetch SUBCOMMAND [options]\n\nSubcommands: #{VALID_SUBCOMMANDS.join(', ')}"
        FetchArgsShared.add_help_option(opts)
      end

      FetchArgsShared.handle_parse_error(parser) do
        if argv.empty?
          raise Args::Error.new("Missing required subcommand.", usage: parser.to_s)
        end

        # Check if first arg is a valid subcommand
        potential_subcommand = argv.first.to_s.strip.downcase
        if VALID_SUBCOMMANDS.include?(potential_subcommand)
          # It's a valid subcommand - extract it and leave rest of args for subcommand parser
          subcommand = argv.shift.to_s.strip.downcase
          Result.new(subcommand: subcommand)
        else
          # Not a valid subcommand - parse flags (which might show help or error)
          parser.parse!(argv)
          
          # If we get here, argv should have the subcommand now
          if argv.empty?
            raise Args::Error.new("Missing required subcommand.", usage: parser.to_s)
          end
          
          subcommand = argv.shift.to_s.strip.downcase
          unless VALID_SUBCOMMANDS.include?(subcommand)
            raise Args::Error.new("Unknown subcommand: #{subcommand.inspect}. Expected one of: #{VALID_SUBCOMMANDS.join(', ')}.", usage: parser.to_s)
          end
          
          Result.new(subcommand: subcommand)
        end
      end
    end
  end
end
