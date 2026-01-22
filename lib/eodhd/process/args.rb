# frozen_string_literal: true

require "optparse"
require_relative "../shared/args"

module Eodhd
  module ProcessArgs
    Result = Data.define(:mode, :exchange_filters, :symbol_filters)

    module_function

    def parse(argv)
      Args.with_exception_handling { parse_args(argv) }
    end

    private

    def parse_args(argv)
      mode = "eod"
      exchange_filters = []
      symbol_filters = []

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: bin/process [options]"

        opts.on("-mMODE", "--mode=MODE", "Mode: eod or intraday (default: eod)") do |v|
          mode = v.to_s.strip
        end

        opts.on("-eFILTER", "--exchange-filter=FILTER", "Exchange substring filter (repeatable or comma-separated)") do |v|
          exchange_filters << v
        end

        opts.on("-sFILTER", "--symbol-filter=FILTER", "Symbol substring filter (repeatable or comma-separated)") do |v|
          symbol_filters << v
        end

        opts.on("-h", "--help", "Show this help") do
          raise Args::Help.new(opts.to_s)
        end
      end

      parser.parse!(argv)

      unless argv.empty?
        raise Args::Error.new("Unexpected arguments: #{argv.join(" ")}.", usage: parser.to_s)
      end

      mode = mode.to_s.strip.downcase
      unless %w[eod intraday].include?(mode)
        raise Args::Error.new("Unknown mode: #{mode.inspect}. Expected 'eod' or 'intraday'.", usage: parser.to_s)
      end

      Result.new(
        mode: mode,
        exchange_filters: normalize_filters(exchange_filters),
        symbol_filters: normalize_filters(symbol_filters)
      )
    rescue OptionParser::ParseError => e
      raise Args::Error.new(e.message, usage: parser.to_s)
    end

    def normalize_filters(filters)
      filters.flat_map { |f| f.to_s.split(",") }
             .map { |s| s.to_s.strip.downcase }
             .reject(&:empty?)
    end
  end
end
