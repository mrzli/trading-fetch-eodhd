# frozen_string_literal: true

require_relative "../../../util"
require_relative "../../shared/path"
require_relative "../../parsing/intraday_csv_parser"

module Eodhd
  class RawIntradayCsvProcessor
    def initialize(container:)
      @log = container.logger
      @io = container.io
    end

    def process(exchange, symbol)
      symbol_with_exchange = "#{symbol}.#{exchange}"
      @log.info("Processing raw intraday for #{symbol_with_exchange}...")

      fetched_dir = Path.raw_intraday_fetched_symbol_data_dir(exchange, symbol)
      fetched_files = list_and_sort_fetched_files(fetched_dir)

      if fetched_files.empty?
        @log.info("No fetched files found for #{symbol_with_exchange}")
        return
      end

      fetched_files.each do |file_path|
        process_file(exchange, symbol, file_path)
      end

      @log.info("Completed processing raw intraday for #{symbol_with_exchange}")
    end

    private

    def list_and_sort_fetched_files(fetched_dir)
      files = @io.list_relative_files(fetched_dir)
      files
        .filter { |path| path.end_with?(".csv") }
        .sort
    end

    def process_file(exchange, symbol, file_path)
      csv_content = @io.read_text(file_path)
      rows = IntradayCsvParser.parse(csv_content)

      return if rows.empty?

      first_timestamp = rows.first[:timestamp]
      last_timestamp = rows.last[:timestamp]

      # Group rows by year-month
      rows_by_month = group_rows_by_month(rows)

      rows_by_month.each do |year_month, month_rows|
        year, month = year_month
        process_month(exchange, symbol, year, month, month_rows, first_timestamp, last_timestamp)
      end
    end

    def group_rows_by_month(rows)
      grouped = {}
      rows.each do |row|
        time = Time.at(row[:timestamp])
        year = time.year
        month = time.month
        key = [year, month]
        grouped[key] ||= []
        grouped[key] << row
      end
      grouped.sort.to_h
    end

    def process_month(exchange, symbol, year, month, new_rows, file_start_ts, file_end_ts)
      processed_file_path = Path.raw_intraday_processed_symbol_year_month(exchange, symbol, year, month)

      existing_rows = load_existing_processed_file(processed_file_path)

      if existing_rows.nil?
        # No existing file, just write new data
        write_processed_file(processed_file_path, new_rows)
      else
        # Crop existing rows for overlapping timestamps
        cropped_rows = crop_rows(existing_rows, file_start_ts, file_end_ts)
        
        # Merge cropped and new rows, sort by timestamp
        merged_rows = (cropped_rows + new_rows).sort_by { |row| row[:timestamp] }
        
        write_processed_file(processed_file_path, merged_rows)
      end
    end

    def load_existing_processed_file(file_path)
      return nil unless @io.file_exists?(file_path)

      csv_content = @io.read_text(file_path)
      IntradayCsvParser.parse(csv_content)
    end

    def crop_rows(rows, exclude_start_ts, exclude_end_ts)
      return rows if rows.empty?

      # Find the index where we should start cropping (first row >= exclude_start_ts)
      start_crop_idx = BinarySearch.lower_bound(rows, exclude_start_ts) { |row| row[:timestamp] }

      # Find the index where we should end cropping (first row > exclude_end_ts)
      end_crop_idx = BinarySearch.upper_bound(rows, exclude_end_ts) { |row| row[:timestamp] }

      # Return rows before start_crop_idx and rows from end_crop_idx onwards
      result = []
      result += rows[0...start_crop_idx] if start_crop_idx > 0
      result += rows[end_crop_idx..-1] if end_crop_idx < rows.length
      result
    end

    def write_processed_file(file_path, rows)
      return if rows.empty?

      # Convert rows back to CSV format
      csv_lines = ["Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume"]
      rows.each do |row|
        csv_lines << "#{row[:timestamp]},#{row[:gmtoffset]},\"#{row[:datetime]}\",#{row[:open]},#{row[:high]},#{row[:low]},#{row[:close]},#{row[:volume]}"
      end

      csv_content = csv_lines.join("\n") + "\n"
      @io.write_csv(file_path, csv_content)
      @log.info("Wrote #{file_path}")
    end
  end
end
