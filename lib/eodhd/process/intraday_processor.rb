# frozen_string_literal: true

require "csv"
require "date"

require_relative "shared/price_adjuster"

module Eodhd
  class IntradayProcessor
    OUTPUT_HEADERS = ["Timestamp", "Datetime", "Open", "High", "Low", "Close", "Volume"].freeze

    class Error < StandardError; end

    class << self
      # Input: array of intraday 1min CSV strings.
      # Output: hash of year(Integer) => processed CSV string.
      #
      # Overlaps are resolved by Timestamp using crop-and-append semantics:
      # when a later input file starts at (or before) an existing timestamp,
      # all existing rows from that insertion point onward are discarded and
      # replaced by the later file's rows.
      def process_csv_files!(raw_csv_files, splits)
        unless raw_csv_files.is_a?(Array)
          raise ArgumentError, "raw_csv_files must be an Array"
        end

        merged_rows = []
        raw_csv_files.each do |raw_csv|
          file_rows = parse_file_rows!(raw_csv)
          next if file_rows.empty?

          if merged_rows.empty?
            merged_rows = file_rows
            next
          end

          merge_in_place!(merged_rows, file_rows)
        end

        return {} if merged_rows.empty?

        factor_cache = {}
        grouped = merged_rows.map do |r|
          factor = (factor_cache[r[:date]] ||= PriceAdjuster.cumulative_split_factor_for_date(r[:date], splits))

          {
            timestamp: r[:timestamp],
            datetime: r[:datetime],
            year: r[:year],
            open: PriceAdjuster.adjust_price(r[:open], factor),
            high: PriceAdjuster.adjust_price(r[:high], factor),
            low: PriceAdjuster.adjust_price(r[:low], factor),
            close: PriceAdjuster.adjust_price(r[:close], factor),
            volume: PriceAdjuster.adjust_volume(r[:volume], factor)
          }
        end.group_by { |r| r[:year] }

        grouped.transform_values do |rows|
          CSV.generate do |out|
            out << OUTPUT_HEADERS

            rows.sort_by { |r| r[:timestamp] }.each do |r|
              out << [
                r[:timestamp].to_s,
                r[:datetime],
                r[:open],
                r[:high],
                r[:low],
                r[:close],
                r[:volume]
              ]
            end
          end
        end
      rescue ArgumentError => e
        raise Error, e.message
      end

      private

      def validate_headers!(headers)
        headers = headers.compact.map(&:to_s)
        required = ["Timestamp", "Gmtoffset", "Datetime", "Open", "High", "Low", "Close", "Volume"]

        missing = required.reject { |h| headers.include?(h) }
        return if missing.empty?

        raise Error, "Missing required columns: #{missing.join(", ")}" 
      end

      def parse_file_rows!(raw_csv)
        raw_csv = Validate.required_string!("raw_csv", raw_csv)

        csv = CSV.parse(raw_csv, headers: true)
        validate_headers!(csv.headers)

        # Last row wins within a file.
        rows_by_timestamp = {}

        csv.each do |row|
          timestamp_str = row["Timestamp"].to_s.strip
          next if timestamp_str.empty?

          gmtoffset_str = row["Gmtoffset"].to_s.strip
          next if gmtoffset_str.empty?

          datetime_str = row["Datetime"].to_s.strip
          next if datetime_str.empty?

          timestamp = Integer(timestamp_str)
          gmtoffset = Integer(gmtoffset_str)

          if gmtoffset != 0
            raise Error, "Only Gmtoffset=0 is supported for now (got #{gmtoffset})"
          end

          date_str = datetime_str.split(" ", 2).first
          date = Date.iso8601(date_str)

          rows_by_timestamp[timestamp] = {
            timestamp: timestamp,
            datetime: datetime_str,
            date: date,
            year: date.year,
            open: Validate.required_string!("open", row["Open"]),
            high: Validate.required_string!("high", row["High"]),
            low: Validate.required_string!("low", row["Low"]),
            close: Validate.required_string!("close", row["Close"]),
            volume: Validate.required_string!("volume", row["Volume"])
          }
        end

        rows_by_timestamp.values.sort_by { |r| r[:timestamp] }
      end

      def merge_in_place!(merged_rows, next_rows)
        return if next_rows.empty?
        return merged_rows.concat(next_rows) if merged_rows.empty?

        next_first = next_rows.first[:timestamp]
        merged_last = merged_rows.last[:timestamp]

        if next_first > merged_last
          merged_rows.concat(next_rows)
          return
        end

        idx = lower_bound_timestamp(merged_rows, next_first)
        merged_rows.slice!(idx, merged_rows.length - idx)
        merged_rows.concat(next_rows)
      end

      def lower_bound_timestamp(rows, timestamp)
        lo = 0
        hi = rows.length

        while lo < hi
          mid = (lo + hi) / 2
          if rows[mid][:timestamp] < timestamp
            lo = mid + 1
          else
            hi = mid
          end
        end

        lo
      end

      # NOTE: GMT offset handling intentionally not implemented yet.
    end
  end
end
