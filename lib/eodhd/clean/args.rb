# frozen_string_literal: true

require "optparse"
require_relative "../shared/args"

module Eodhd
  module CleanArgs
    Result = Data.define(:command, :yes)

    class << self
      def parse(argv)
        Args.with_exception_handling { parse_args(argv) }
      end

      private

      def parse_args(argv)
        yes = false

        parser = OptionParser.new do |opts|
          opts.banner = "Usage: bin/clean COMMAND [options]\n\nCommands: exchanges, symbols"

          opts.on("-y", "--yes", "Skip confirmation prompt") do
            yes = true
          end

          opts.on("-h", "--help", "Show this help") do
            raise Args::Help.new(opts.to_s)
          end
        end

        parser.parse!(argv)

        if argv.empty?
          raise Args::Error.new("Missing required command.", usage: parser.to_s)
        end

        command = argv.shift.to_s.strip.downcase
        unless %w[exchanges symbols].include?(command)
          raise Args::Error.new("Unknown command: #{command.inspect}. Expected 'exchanges' or 'symbols'.", usage: parser.to_s)
        end

        unless argv.empty?
          raise Args::Error.new("Unexpected arguments: #{argv.join(" ")}.", usage: parser.to_s)
        end

        Result.new(command: command, yes: yes)
      rescue OptionParser::ParseError => e
        raise Args::Error.new(e.message, usage: parser.to_s)
      end
    end
  end
end
