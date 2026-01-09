# frozen_string_literal: true

require "csv"
require "date"

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

      inputs = raw_csv_list.drop(70).map.with_index do |raw_csv, index|
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

      splits = SplitProcessor.process(splits)
      data = PriceAdjust.apply(data, splits)

      data_items = DataSplitter.by_month(data)

      puts data_items.class, data_items.size, data_items[0].class
      puts data_items[0].inspect.to_s[0..500]

      data = to_output(data)
      to_csv(data)
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
          open: row[:open].to_s("F"),
          high: row[:high].to_s("F"),
          low: row[:low].to_s("F"),
          close: row[:close].to_s("F"),
          volume: row[:volume].to_s
        }
      end
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
