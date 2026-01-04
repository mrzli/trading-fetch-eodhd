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

    def run!
      process_eod!
    end

    private

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

          processed_csv = EodProcessor.process_csv!(raw_csv, splits_json)
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
  end
end
