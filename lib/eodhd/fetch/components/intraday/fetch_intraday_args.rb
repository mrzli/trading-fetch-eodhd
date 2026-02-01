# frozen_string_literal: true

require "optparse"
require_relative "../../../shared/args"

module Eodhd
  class FetchIntradayArgs
    Result = Data.define(:recheck_start_date, :parallel, :workers)

    def initialize(container:)
      @cfg = container.config
    end

    def parse(argv)
      Args.with_exception_handling { parse_args(argv) }
    end

    private

    def parse_args(argv)
      recheck_start_date = false
      parallel = false
      workers = @cfg.default_workers

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: bin/fetch intraday [options]"

        opts.on("-r", "--recheck-start-date", "Recheck data from start date") do
          recheck_start_date = true
        end

        opts.on("-p", "--parallel", "Use parallel processing") do
          parallel = true
        end

        opts.on("-w", "--workers N", Integer, "Number of parallel workers (default: #{@cfg.default_workers})") do |v|
          workers = Validate.integer_positive("workers", v)
        end

        opts.on("-h", "--help", "Show this help") do
          raise Args::Help.new(opts.to_s)
        end
      end

      parser.parse!(argv)

      unless argv.empty?
        raise Args::Error.new("Unexpected arguments: #{argv.join(" ")}.", usage: parser.to_s)
      end

      Result.new(recheck_start_date: recheck_start_date, parallel: parallel, workers: workers)
    rescue OptionParser::ParseError => e
      raise Args::Error.new(e.message, usage: parser.to_s)
    end
  end
end
