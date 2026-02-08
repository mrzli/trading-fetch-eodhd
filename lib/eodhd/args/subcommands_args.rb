# frozen_string_literal: true

require "optparse"

module Eodhd
  module Args
    class SubcommandsArgs
      Result = Data.define(:subcommand)

      def initialize(container:, command_name:, valid_subcommands:)
        @cfg = container.config
        @command_name = command_name
        @valid_subcommands = valid_subcommands
      end

      def parse(argv)
        Eodhd::Shared::Args.with_exception_handling { parse_args(argv) }
      end

      private

      def parse_args(argv)
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: bin/#{@command_name} SUBCOMMAND [options]\n\nSubcommands: #{@valid_subcommands.join(', ')}"
          Eodhd::Args::Shared.add_help_option(opts)
        end

        Eodhd::Args::Shared.handle_parse_error(parser) do
          if argv.empty?
            raise Eodhd::Shared::Args::Error.new("Missing required subcommand.", usage: parser.to_s)
          end
        end

        # Check if first arg is a valid subcommand
        potential_subcommand = argv.first.to_s.strip.downcase
        if @valid_subcommands.include?(potential_subcommand)
          # It's a valid subcommand - extract it and leave rest of args for subcommand parser
          subcommand = argv.shift.to_s.strip.downcase
          Result.new(subcommand: subcommand)
        else
          # Not a valid subcommand - parse flags (which might show help or error)
          parser.parse!(argv)

          # If we get here, argv should have the subcommand now
          if argv.empty?
            raise Eodhd::Shared::Args::Error.new("Missing required subcommand.", usage: parser.to_s)
          end

          subcommand = argv.shift.to_s.strip.downcase
          unless @valid_subcommands.include?(subcommand)
            raise Eodhd::Shared::Args::Error.new("Unknown subcommand: #{subcommand.inspect}. Expected one of: #{@valid_subcommands.join(', ')}.", usage: parser.to_s)
          end

          Result.new(subcommand: subcommand)
        end
      end
    end
  end
end
