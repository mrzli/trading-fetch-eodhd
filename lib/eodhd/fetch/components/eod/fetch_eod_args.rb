# frozen_string_literal: true

require "optparse"
require_relative "../../../shared/args"

module Eodhd
  class FetchEodArgs
    Result = Data.define(:force, :parallel, :workers)

    def initialize(container:)
      @cfg = container.config
    end

    def parse(argv)
      Args.with_exception_handling { parse_args(argv) }
    end

    private

    def parse_args(argv)
      force = false
      parallel = false
      workers = @cfg.default_workers

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: bin/fetch eod [options]"

        opts.on("-f", "--force", "Force fetch, ignore file staleness") do
          force = true
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

      Result.new(force: force, parallel: parallel, workers: workers)
    rescue OptionParser::ParseError => e
      raise Args::Error.new(e.message, usage: parser.to_s)
    end
  end
end
