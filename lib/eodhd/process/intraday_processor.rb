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
      # Overlaps are resolved by Timestamp; later input files win.
      def process_csv_files!(raw_csv_files, splits)
        unless raw_csv_files.is_a?(Array)
          raise ArgumentError, "raw_csv_files must be an Array"
        end

        rows_by_timestamp = {}
        factor_cache = {}

        raw_csv_files.each do |raw_csv|
          raw_csv = Validate.required_string!("raw_csv", raw_csv)

          csv = CSV.parse(raw_csv, headers: true)
          validate_headers!(csv.headers)

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

            factor = (factor_cache[date_str] ||= PriceAdjuster.cumulative_split_factor_for_date(date, splits))

            rows_by_timestamp[timestamp] = {
              timestamp: timestamp,
              datetime: datetime_str,
              year: date.year,
              open: PriceAdjuster.adjust_price(row["Open"], factor),
              high: PriceAdjuster.adjust_price(row["High"], factor),
              low: PriceAdjuster.adjust_price(row["Low"], factor),
              close: PriceAdjuster.adjust_price(row["Close"], factor),
              volume: PriceAdjuster.adjust_volume(row["Volume"], factor)
            }
          end
        end

        grouped = rows_by_timestamp.values.group_by { |r| r[:year] }

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

      # NOTE: GMT offset handling intentionally not implemented yet.
    end
  end
end
