# frozen_string_literal: true

require "optparse"
require_relative "../../../shared/args"

module Eodhd
  class FetchExchangesArgs
    Result = Data.define(:force)

    def initialize(container:)
      @cfg = container.config
    end

    def parse(argv)
      Args.with_exception_handling { parse_args(argv) }
    end

    private

    def parse_args(argv)
      force = false

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: bin/fetch exchanges [options]"

        opts.on("-f", "--force", "Force fetch, ignore file staleness") do
          force = true
        end

        opts.on("-h", "--help", "Show this help") do
          raise Args::Help.new(opts.to_s)
        end
      end

      parser.parse!(argv)

      unless argv.empty?
        raise Args::Error.new("Unexpected arguments: #{argv.join(" ")}.", usage: parser.to_s)
      end

      Result.new(force: force)
    rescue OptionParser::ParseError => e
      raise Args::Error.new(e.message, usage: parser.to_s)
    end
  end
end
