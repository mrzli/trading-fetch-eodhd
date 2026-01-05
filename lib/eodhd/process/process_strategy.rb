# frozen_string_literal: true

require "json"
require "set"
require "time"
require "pathname"

module Eodhd
  class ProcessStrategy
    def initialize(log:, cfg:, io:)
      @log = log
      @cfg = cfg
      @io = io
    end

    def process_eod!
      raw_dir = File.join(@cfg.output_dir, "raw", "eod")
      unless Dir.exist?(raw_dir)
        @log.info("No raw EOD directory found: #{raw_dir}")
        return
      end

      raw_files = Dir.glob(File.join(raw_dir, "**", "*.csv")).sort
      if raw_files.empty?
        @log.info("No raw EOD CSV files found under: #{raw_dir}")
        return
      end

      raw_files.each do |raw_abs|
        rel = Pathname.new(raw_abs).relative_path_from(Pathname.new(@cfg.output_dir)).to_s

        match = rel.match(%r{\Araw/eod/([^/]+)/([^/]+)\.csv\z})
        unless match
          @log.warn("Skipping unexpected EOD path: #{rel}")
          next
        end

        exchange = match[1]
        symbol = match[2]

        processed_rel = Path.processed_eod_data(exchange, symbol)
        splits_rel = Path.splits(exchange, symbol)

        unless should_process_eod?(raw_rel: rel, splits_rel: splits_rel, processed_rel: processed_rel)
          @log.info("Skipping processed EOD (fresh): #{processed_rel}")
          next
        end

        begin
          raw_csv = @io.read_text(rel)
          splits_json = @io.file_exists?(splits_rel) ? @io.read_text(splits_rel) : ""

          splits = SplitsParser.parse_splits!(splits_json)

          processed_csv = EodProcessor.process_csv!(raw_csv, splits)
          saved_path = @io.save_csv!(processed_rel, processed_csv)
          @log.info("Wrote #{saved_path}")
        rescue StandardError => e
          @log.warn("Failed processing EOD for #{exchange}/#{symbol}: #{e.class}: #{e.message}")
        end
      end
    end

    def should_process_eod?(raw_rel:, splits_rel:, processed_rel:)
      processed_mtime = @io.file_last_updated_at(processed_rel)
      return true if processed_mtime.nil?

      raw_mtime = @io.file_last_updated_at(raw_rel)
      return true if raw_mtime && raw_mtime > processed_mtime

      splits_mtime = @io.file_last_updated_at(splits_rel)
      return true if splits_mtime && splits_mtime > processed_mtime

      false
    end

    def process_intraday!
      raw_root = File.join(@cfg.output_dir, "raw", "intraday")
      unless Dir.exist?(raw_root)
        @log.info("No raw intraday directory found: #{raw_root}")
        return
      end

      exchanges = Dir.children(raw_root).select { |name| Dir.exist?(File.join(raw_root, name)) }.sort
      if exchanges.empty?
        @log.info("No exchange directories found under: #{raw_root}")
        return
      end

      exchanges.each do |exchange|
        exchange_dir = File.join(raw_root, exchange)
        symbols = Dir.children(exchange_dir).select { |name| Dir.exist?(File.join(exchange_dir, name)) }.sort
        next if symbols.empty?

        symbols.each do |symbol|
          symbol_dir = File.join(exchange_dir, symbol)
          raw_abs_files = Dir.glob(File.join(symbol_dir, "*.csv")).sort
          next if raw_abs_files.empty?

          raw_rels = raw_abs_files.map do |abs|
            Pathname.new(abs).relative_path_from(Pathname.new(@cfg.output_dir)).to_s
          end

          splits_rel = Path.splits(exchange, symbol)
          processed_dir_rel = Path.processed_intraday_data_dir(exchange, symbol)

          unless should_process_intraday?(raw_rels: raw_rels, splits_rel: splits_rel, processed_dir_rel: processed_dir_rel)
            @log.info("Skipping processed intraday (fresh): #{processed_dir_rel}")
            next
          end

          begin
            splits_json = @io.file_exists?(splits_rel) ? @io.read_text(splits_rel) : ""
            splits = SplitsParser.parse_splits!(splits_json)

            raw_csv_files = raw_rels.map { |rel| @io.read_text(rel) }
            outputs = IntradayProcessor.process_csv_files!(raw_csv_files, splits)

            if outputs.empty?
              @log.info("No intraday rows produced for #{exchange}/#{symbol}")
              next
            end

            outputs.keys.sort.each do |year|
              processed_rel = Path.processed_intraday_year(exchange, symbol, year)
              saved_path = @io.save_csv!(processed_rel, outputs.fetch(year))
              @log.info("Wrote #{saved_path}")
            end
          rescue StandardError => e
            @log.warn("Failed processing intraday for #{exchange}/#{symbol}: #{e.class}: #{e.message}")
          end
        end
      end
    end

    def should_process_intraday?(raw_rels:, splits_rel:, processed_dir_rel:)
      processed_paths = @io.list_relative_paths(processed_dir_rel)
      processed_mtime = processed_paths.map { |p| @io.file_last_updated_at(p) }.compact.max
      return true if processed_mtime.nil?

      raw_latest = raw_rels.map { |p| @io.file_last_updated_at(p) }.compact.max
      return true if raw_latest && raw_latest > processed_mtime

      splits_mtime = @io.file_last_updated_at(splits_rel)
      return true if splits_mtime && splits_mtime > processed_mtime

      false
    end

    private
  end
end
