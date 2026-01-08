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
      rows = build_output_rows(parsed_rows, splits)
      generate_csv(rows)
    rescue EodCsvParser::Error => e
      raise Error, e.message
    end

    private

    def build_output_rows(parsed_rows, splits)
      parsed_rows.map do |row|
        factor = PriceAdjuster.cumulative_split_factor_for_date(row[:date], splits)

        {
          date: row[:date].iso8601,
          open: PriceAdjuster.adjust_price(row[:open].to_s("F"), factor),
          high: PriceAdjuster.adjust_price(row[:high].to_s("F"), factor),
          low: PriceAdjuster.adjust_price(row[:low].to_s("F"), factor),
          close: PriceAdjuster.adjust_price(row[:close].to_s("F"), factor),
          volume: PriceAdjuster.adjust_volume(row[:volume].to_s, factor)
        }
      end
    end

    def generate_csv(rows)
      CSV.generate do |out_csv|
        out_csv << OUTPUT_HEADERS

        rows.each do |row|
          out_csv << [
            row[:date],
            row[:open],
            row[:high],
            row[:low],
            row[:close],
            row[:volume]
          ]
        end
      end
    end
  end
end
