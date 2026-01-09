# frozen_string_literal: true

require "csv"
require "date"

require_relative "eod_csv_parser"
require_relative "../shared/constants"
require_relative "../shared/price_adjust"
require_relative "../shared/splits_processor"

module Eodhd
  class EodCsvProcessor
    OUTPUT_HEADERS = ["Date", "Open", "High", "Low", "Close", "Volume"].freeze

    class Error < StandardError; end

    def initialize(log:)
      @log = log
    end

    def process_csv(raw_csv, splits)
      data = EodCsvParser.parse(raw_csv)
      splits = SplitsProcessor.process(splits)
      data = PriceAdjust.apply(data, splits)
      data = to_output(data)
      to_csv(data)
    rescue EodCsvParser::Error => e
      raise Error, e.message
    end

    private

    def to_output(data)
      data.map do |row|
        {
          date: row[:date].iso8601,
          open: format_price(row[:open]),
          high: format_price(row[:high]),
          low: format_price(row[:low]),
          close: format_price(row[:close]),
          volume: row[:volume].to_s
        }
      end
    end

    def format_price(price)
      price.round(Constants::OUTPUT_DECIMALS).to_s
    end

    def to_csv(rows)
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
