# frozen_string_literal: true

require_relative "../../../parsing/dividends_parser"
require_relative "../../../parsing/splits_parser"
require_relative "intraday_csv_processor"

module Eodhd
  module Commands
    module Process
      module Intraday
        class Run
          def initialize(log:, io:)
            @log = log
            @io = io
            @processor = IntradayCsvProcessor.new(log: log)
          end

      def process
        raw_root = @io.output_path(Shared::Path.raw_intraday_dir)
        unless Dir.exist?(raw_root)
          @log.info("No raw intraday directory found: #{raw_root}")
          return
        end

        exchanges = Dir.children(raw_root).select { |name| Dir.exist?(File.join(raw_root, name)) }
        exchanges.sort!
        if exchanges.empty?
          @log.info("No exchange directories found under: #{raw_root}")
          return
        end

        exchanges.each do |exchange|
          exchange_dir = File.join(raw_root, exchange)
          process_exchange(exchange, exchange_dir)
        end
      end

      private

      def process_exchange(exchange, exchange_dir)
        symbols = Dir.children(exchange_dir).select { |name| Dir.exist?(File.join(exchange_dir, name)) }
        symbols.sort!
        return if symbols.empty?

        symbols.each do |symbol|
          symbol_dir = File.join(exchange_dir, symbol)
          process_symbol(exchange, symbol, symbol_dir)
        end
      end

      def process_symbol(exchange, symbol, symbol_dir)
        raw_abs_files = Dir.glob(File.join(symbol_dir, "*.csv")).sort
        return if raw_abs_files.empty?

        raw_rels = raw_abs_files.map { |abs| @io.relative_path(abs) }

        splits_rel = Eodhd::Shared::Path.splits(exchange, symbol)
        dividends_rel = Eodhd::Shared::Path.dividends(exchange, symbol)
        processed_dir_rel = Eodhd::Shared::Path.processed_intraday_data_dir(exchange, symbol)

        unless should_process?(raw_rels: raw_rels, splits_rel: splits_rel, processed_dir_rel: processed_dir_rel)
          @log.info("Skipping processed intraday (fresh): #{processed_dir_rel}")
          return
        end

        raw_csv_files = raw_rels.map { |rel| @io.read_text(rel) }

        splits_json = @io.file_exists?(splits_rel) ? @io.read_text(splits_rel) : nil
        splits = splits_json ? Eodhd::Parsing::SplitsParser.parse(splits_json) : []
        dividends_json = @io.file_exists?(dividends_rel) ? @io.read_text(dividends_rel) : ""
        dividends = Eodhd::Parsing::DividendsParser.parse(dividends_json)

        outputs = @processor.process_csv_list(raw_csv_files, splits, dividends)
        if outputs.empty?
          @log.info("No intraday rows produced for #{exchange}/#{symbol}")
          return
        end

        outputs.each do |item|
          item in { key: key, csv: csv }
          processed_rel = Eodhd::Shared::Path.processed_intraday_year_month(exchange, symbol, key.year, key.month)
          saved_path = @io.write_csv(processed_rel, csv)
          @log.info("Wrote #{Util::String.truncate_middle(saved_path)}")
        end
      rescue StandardError => e
        @log.warn("Failed processing intraday for #{exchange}/#{symbol}: #{e.class}: #{e.message}")
      end

      def should_process?(raw_rels:, splits_rel:, processed_dir_rel:)
        processed_paths = @io.list_relative_files(processed_dir_rel)
        processed_mtime = processed_paths.map { |p| @io.file_last_updated_at(p) }.compact.max
        return true if processed_mtime.nil?

        raw_latest = raw_rels.map { |p| @io.file_last_updated_at(p) }.compact.max
        return true if raw_latest && raw_latest > processed_mtime

        splits_mtime = @io.file_last_updated_at(splits_rel)
        return true if splits_mtime && splits_mtime > processed_mtime

        false
      end
        end
      end
    end
  end
end
