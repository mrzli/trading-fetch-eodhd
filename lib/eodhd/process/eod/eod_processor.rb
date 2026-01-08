# frozen_string_literal: true

require "bigdecimal"
require "bigdecimal/util"
require "csv"
require "date"

require_relative "../../../util"
require_relative "../shared/price_adjuster"

module Eodhd
  class EodProcessor
    OUTPUT_HEADERS = ["Date", "Open", "High", "Low", "Close", "Volume"].freeze

    class Error < StandardError; end

    def initialize(log:)
      @log = log
    end

    def process_csv!(raw_csv, splits)
      raw_csv = Validate.required_string!("raw_csv", raw_csv)

      csv = CSV.parse(raw_csv, headers: true)
      validate_headers!(csv.headers)

      out = CSV.generate do |out_csv|
        out_csv << OUTPUT_HEADERS

        csv.each do |row|
          date_str = row["Date"].to_s.strip
          next if date_str.empty?

          date = Date.iso8601(date_str)
          factor = PriceAdjuster.cumulative_split_factor_for_date(date, splits)

          out_csv << [
            date_str,
            PriceAdjuster.adjust_price(row["Open"], factor),
            PriceAdjuster.adjust_price(row["High"], factor),
            PriceAdjuster.adjust_price(row["Low"], factor),
            PriceAdjuster.adjust_price(row["Close"], factor),
            PriceAdjuster.adjust_volume(row["Volume"], factor)
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
      if missing.any?
        raise Error, "Missing required columns: #{missing.join(", ")}" 
      end
    end
  end
end
