# frozen_string_literal: true

require "optparse"
require_relative "../shared/args"

module Eodhd
  module FetchArgs
    Result = Data.define(:subcommand)

    class << self
      def parse(argv)
        Args.with_exception_handling { parse_args(argv) }
      end

      private

      def parse_args(argv)
        subcommand = "exchanges"

        parser = OptionParser.new do |opts|
          opts.banner = "Usage: bin/fetch [options]"

          opts.on("-cSUBCOMMAND", "--subcommand=SUBCOMMAND", "Subcommand: exchanges or symbols (default: exchanges)") do |v|
            subcommand = v.to_s.strip
          end

          opts.on("-h", "--help", "Show this help") do
            raise Args::Help.new(opts.to_s)
          end
        end

        parser.parse!(argv)

        unless argv.empty?
          raise Args::Error.new("Unexpected arguments: #{argv.join(" ")}.", usage: parser.to_s)
        end

        subcommand = subcommand.to_s.strip.downcase
        unless %w[exchanges symbols].include?(subcommand)
          raise Args::Error.new("Unknown subcommand: #{subcommand.inspect}. Expected 'exchanges' or 'symbols'.", usage: parser.to_s)
        end

        Result.new(subcommand: subcommand)
      rescue OptionParser::ParseError => e
        raise Args::Error.new(e.message, usage: parser.to_s)
      end
    end
  end
end
