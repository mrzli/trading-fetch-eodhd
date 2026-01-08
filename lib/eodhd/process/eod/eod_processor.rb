# frozen_string_literal: true

require "bigdecimal"
require "csv"
require "date"

require_relative "eod_csv_parser"
require_relative "../shared/price_adjuster"
require_relative "../shared/split_processor"

module Eodhd
  class EodProcessor
    OUTPUT_HEADERS = ["Date", "Open", "High", "Low", "Close", "Volume"].freeze

    class Error < StandardError; end

    def initialize(log:)
      @log = log
    end

    def process_csv(raw_csv, splits)
      data = EodCsvParser.parse(raw_csv)
      # splits = SplitProcessor.process(splits)
      data = adjust(data, splits)
      data = to_output(data)
      to_csv(data)
    rescue EodCsvParser::Error => e
      raise Error, e.message
    end

    private

    def adjust(data, splits)
      if splits.empty?
        return data
      end

      data.map do |row|
        factor = PriceAdjuster.cumulative_split_factor_for_date(row[:date], splits)

        {
          date: row[:date],
          open: PriceAdjuster.adjust_price(row[:open], factor),
          high: PriceAdjuster.adjust_price(row[:high], factor),
          low: PriceAdjuster.adjust_price(row[:low], factor),
          close: PriceAdjuster.adjust_price(row[:close], factor),
          volume: PriceAdjuster.adjust_volume(row[:volume], factor)
        }
      end
    end

    def to_output(data)
      data.map do |row|
        {
          date: row[:date].iso8601,
          open: row[:open].to_s("F"),
          high: row[:high].to_s("F"),
          low: row[:low].to_s("F"),
          close: row[:close].to_s("F"),
          volume: row[:volume].to_s,
        }
      end
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
