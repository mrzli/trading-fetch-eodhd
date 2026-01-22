# frozen_string_literal: true

require "optparse"

module Eodhd
  module FetchArgs
    class Error < StandardError
      attr_reader :usage

      def initialize(message, usage: nil)
        super(message)
        @usage = usage
      end
    end

    class Help < StandardError
      attr_reader :usage

      def initialize(usage)
        super("help")
        @usage = usage
      end
    end

    Result = Data.define(:subcommand)

    module_function

    def parse(argv)
      parse_args(argv)
    rescue Help => e
      puts e.usage
      exit 0
    rescue Error => e
      warn e.message
      warn e.usage if e.usage
      exit 2
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
          raise Help.new(opts.to_s)
        end
      end

      parser.parse!(argv)

      unless argv.empty?
        raise Error.new("Unexpected arguments: #{argv.join(" ")}.", usage: parser.to_s)
      end

      subcommand = subcommand.to_s.strip.downcase
      unless %w[exchanges symbols].include?(subcommand)
        raise Error.new("Unknown subcommand: #{subcommand.inspect}. Expected 'exchanges' or 'symbols'.", usage: parser.to_s)
      end

      Result.new(subcommand: subcommand)
    rescue OptionParser::ParseError => e
      raise Error.new(e.message, usage: parser.to_s)
    end
  end
end
