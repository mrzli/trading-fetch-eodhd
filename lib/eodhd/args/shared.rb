# frozen_string_literal: true

require "optparse"

module Eodhd
  module Args
    module Shared
      module_function

      def check_args(argv, parser)
        unless argv.empty?
          raise Eodhd::Shared::Args::Error.new("Unexpected arguments: #{argv.join(' ')}.", usage: parser.to_s)
        end
      end

      def add_help_option(opts)
        opts.on("-h", "--help", "Show this help") do
          raise Eodhd::Shared::Args::Help.new(opts.to_s)
        end
      end

      def add_force_option(opts, &block)
        opts.on("-f", "--force", "Force fetch, ignore file staleness") do
          block.call(true)
        end
      end

      def add_parallel_option(opts, &block)
        opts.on("-p", "--parallel", "Use parallel processing") do
          block.call(true)
        end
      end

      def add_workers_option(opts, default_workers, &block)
        opts.on("-w", "--workers N", Integer, "Number of parallel workers (default: #{default_workers})") do |v|
          workers = Util::Validate.integer_positive("workers", v)
          block.call(workers)
        end
      end

      def add_recheck_start_date_option(opts, &block)
        opts.on("-r", "--recheck-start-date", "Recheck data from start date") do
          block.call(true)
        end
      end

      def add_yes_option(opts, &block)
        opts.on("-y", "--yes", "Skip confirmation prompt") do
          block.call(true)
        end
      end

      def add_dry_run_option(opts, &block)
        opts.on("-n", "--dry-run", "Show what would be deleted without deleting") do
          block.call(true)
        end
      end

      def handle_parse_error(parser)
        yield
      rescue OptionParser::ParseError => e
        raise Eodhd::Shared::Args::Error.new(e.message, usage: parser.to_s)
      end
    end
  end
end
