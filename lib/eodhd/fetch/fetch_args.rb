# frozen_string_literal: true

require "optparse"
require_relative "../shared/args"

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

        opts.on("-h", "--help", "Show this help") do
          raise Args::Help.new(opts.to_s)
        end
      end

      parser.parse!(argv)

      if argv.empty?
        raise Args::Error.new("Missing required subcommand.", usage: parser.to_s)
      end

      subcommand = argv.shift.to_s.strip.downcase
      unless VALID_SUBCOMMANDS.include?(subcommand)
        raise Args::Error.new("Unknown subcommand: #{subcommand.inspect}. Expected one of: #{VALID_SUBCOMMANDS.join(', ')}.", usage: parser.to_s)
      end

      Result.new(subcommand: subcommand)
    rescue OptionParser::ParseError => e
      raise Args::Error.new(e.message, usage: parser.to_s)
    end
  end
end
