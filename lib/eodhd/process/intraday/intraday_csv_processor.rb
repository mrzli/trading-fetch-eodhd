# frozen_string_literal: true

require "csv"
require "date"

require_relative "../shared/constants"
require_relative "../shared/price_adjust"
require_relative "../shared/split_processor"
require_relative "data_splitter"
require_relative "intraday_csv_parser"
require_relative "input_merger"

module Eodhd
  class IntradayCsvProcessor
    OUTPUT_HEADERS = ["Timestamp", "Datetime", "Open", "High", "Low", "Close", "Volume"].freeze

    class Error < StandardError; end

    def initialize(log:)
      @log = log
    end

    def process_csv_list(raw_csv_list, splits)
      unless raw_csv_list.is_a?(Array)
        raise ArgumentError, "raw_csv_list must be an Array"
      end

      inputs = raw_csv_list.drop(0).map.with_index do |raw_csv, index|
        parsed = IntradayCsvParser.parse(raw_csv)
        if parsed.empty?
          @log.info("Skipped empty intraday CSV file #{index + 1} with size #{raw_csv.bytesize} bytes")
          next
        end

        first = parsed.first
        last = parsed.last
        @log.info("Parsed intraday CSV file #{index + 1} for interval #{first[:datetime]} - #{last[:datetime]} with size #{raw_csv.bytesize} bytes")

        parsed
      end

      data = InputMerger.merge(inputs)

      @log.info("Merged intraday rows. Total rows: #{data.size}.")

      splits = SplitProcessor.process(splits)

      @log.info("Processed splits.")

      data = PriceAdjust.apply(data, splits)

      @log.info("Applied price adjustments.")

      data_items = DataSplitter.by_month(data)

      @log.info("Split intraday data into #{data_items.size} month(s).")

      data_items.map do |item|
        item in { key:, value: }

        value = to_output(value)
        csv = to_csv(value)

        @log.info("Generated CSV for #{key.to_s} with #{value.size} rows.")
        
        {
          key: key,
          csv: csv
        }
      end
    rescue IntradayCsvParser::Error => e
      raise Error, e.message
    rescue ArgumentError => e
      raise Error, e.message
    end

    private

    def to_output(data)
      data.map do |row|
        {
          timestamp: row[:timestamp].to_s,
          datetime: row[:datetime],
          open: format_price(row[:open]),
          high: format_price(row[:high]),
          low: format_price(row[:low]),
          close: format_price(row[:close]),
          volume: row[:volume].to_s
        }
      end
    end

    def format_price(price)
      price.round(Constants::OUTPUT_DECIMALS).to_s("F")
    end

    def to_csv(rows)
      CSV.generate do |out_csv|
        out_csv << OUTPUT_HEADERS

        rows.each do |row|
          out_csv << [
            row[:timestamp],
            row[:datetime],
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
