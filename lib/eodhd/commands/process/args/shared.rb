# frozen_string_literal: true

require "optparse"
require_relative "../../../shared/args"

module Eodhd
  module Commands
    module ProcessArgsShared
      module_function

      def check_args(argv, parser)
        unless argv.empty?
          raise Shared::Args::Error.new("Unexpected arguments: #{argv.join(" ")}.", usage: parser.to_s)
        end
      end

      def add_help_option(opts)
        opts.on("-h", "--help", "Show this help") do
          raise Shared::Args::Help.new(opts.to_s)
        end
      end

      def handle_parse_error(parser)
        yield
      rescue OptionParser::ParseError => e
        raise Shared::Args::Error.new(e.message, usage: parser.to_s)
      end
    end
  end
end
