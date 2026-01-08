# frozen_string_literal: true

require "bigdecimal"
require "csv"
require "date"

require_relative "eod_csv_parser"
require_relative "../shared/price_adjuster"

module Eodhd
  class EodProcessor
    OUTPUT_HEADERS = ["Date", "Open", "High", "Low", "Close", "Volume"].freeze

    class Error < StandardError; end

    def initialize(log:)
      @log = log
    end

    def process_csv(raw_csv, splits)
      parsed_rows = EodCsvParser.parse(raw_csv)

      CSV.generate do |out_csv|
        out_csv << OUTPUT_HEADERS

        parsed_rows.each do |row|
          factor = PriceAdjuster.cumulative_split_factor_for_date(row[:date], splits)

          out_csv << [
            row[:date].iso8601,
            PriceAdjuster.adjust_price(row[:open].to_s("F"), factor),
            PriceAdjuster.adjust_price(row[:high].to_s("F"), factor),
            PriceAdjuster.adjust_price(row[:low].to_s("F"), factor),
            PriceAdjuster.adjust_price(row[:close].to_s("F"), factor),
            PriceAdjuster.adjust_volume(row[:volume].to_s, factor)
          ]
        end
      end
    rescue EodCsvParser::Error => e
      raise Error, e.message
    end

  end
end
