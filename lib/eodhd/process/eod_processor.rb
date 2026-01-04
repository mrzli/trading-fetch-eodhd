# frozen_string_literal: true

require "bigdecimal"
require "bigdecimal/util"
require "csv"
require "date"

module Eodhd
  class EodProcessor
    OUTPUT_HEADERS = ["Date", "Open", "High", "Low", "Close", "Volume"].freeze

    class Error < StandardError; end

    class << self
      def process_csv!(raw_csv, splits_json)
        raw_csv = Validate.required_string!("raw_csv", raw_csv)
        splits = SplitsParser.parse_splits!(splits_json)

        csv = CSV.parse(raw_csv, headers: true)
        validate_headers!(csv.headers)

        out = CSV.generate do |out_csv|
          out_csv << OUTPUT_HEADERS

          csv.each do |row|
            date_str = row["Date"].to_s.strip
            next if date_str.empty?

            date = Date.iso8601(date_str)
            factor = cumulative_factor_for_date(date, splits)

            out_csv << [
              date_str,
              adjust_price(row["Open"], factor),
              adjust_price(row["High"], factor),
              adjust_price(row["Low"], factor),
              adjust_price(row["Close"], factor),
              adjust_volume(row["Volume"], factor)
            ]
          end
        end

        out
      end

      private

      def validate_headers!(headers)
        headers = headers.compact.map(&:to_s)
        required = ["Date", "Open", "High", "Low", "Close", "Volume"]

        missing = required.reject { |h| headers.include?(h) }
        return if missing.empty?

        raise Error, "Missing required columns: #{missing.join(", ")}" 
      end

      # Referent price is the latest price.
      # Rows strictly before a split date must be adjusted by the product of all
      # split factors whose date is after the row date.
      def cumulative_factor_for_date(date, splits)
        return Rational(1, 1) if splits.empty?

        # Find the first split whose date is strictly greater than the row date.
        idx = upper_bound_split_date(splits, date)
        return Rational(1, 1) if idx >= splits.length

        # Product of all split factors from idx..end.
        factor = Rational(1, 1)
        (idx...splits.length).each do |i|
          factor *= splits[i].factor
        end
        factor
      end

      def upper_bound_split_date(splits, date)
        lo = 0
        hi = splits.length

        while lo < hi
          mid = (lo + hi) / 2
          if splits[mid].date <= date
            lo = mid + 1
          else
            hi = mid
          end
        end

        lo
      end

      def rational_to_bigdecimal(r)
        BigDecimal(r.numerator.to_s) / BigDecimal(r.denominator.to_s)
      end

      def adjust_price(value, factor)
        value = Validate.required_string!("price", value)
        bd = BigDecimal(value)
        factor_bd = rational_to_bigdecimal(factor)
        (bd / factor_bd).to_s("F")
      end

      def adjust_volume(value, factor)
        value = Validate.required_string!("volume", value)
        vol = Integer(value)

        adjusted = Rational(vol, 1) * factor
        if adjusted.denominator == 1
          adjusted.numerator.to_s
        else
          (rational_to_bigdecimal(adjusted)).to_s("F")
        end
      rescue ArgumentError
        raise Error, "Invalid volume: #{value.inspect}"
      end
    end
  end
end
