# frozen_string_literal: true

require "csv"
require "date"

require_relative "../shared/split_processor"
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

      puts splits.inspect

      # return {} if merged_rows.empty?

      # factor_cache = {}
      # grouped = merged_rows.map do |r|
      #   factor = (factor_cache[r[:date]] ||= PriceAdjuster.cumulative_split_factor_for_date(r[:date], splits))

      #   {
      #     timestamp: r[:timestamp],
      #     datetime: r[:datetime],
      #     year: r[:year],
      #     open: PriceAdjuster.adjust_price(r[:open], factor),
      #     high: PriceAdjuster.adjust_price(r[:high], factor),
      #     low: PriceAdjuster.adjust_price(r[:low], factor),
      #     close: PriceAdjuster.adjust_price(r[:close], factor),
      #     volume: PriceAdjuster.adjust_volume(r[:volume], factor)
      #   }
      # end.group_by { |r| r[:year] }

      # grouped.transform_values do |rows|
      #   CSV.generate do |out|
      #     out << OUTPUT_HEADERS

      #     rows.sort_by { |r| r[:timestamp] }.each do |r|
      #       out << [
      #         r[:timestamp].to_s,
      #         r[:datetime],
      #         r[:open],
      #         r[:high],
      #         r[:low],
      #         r[:close],
      #         r[:volume]
      #       ]
      #     end
      #   end
      # end
      # 
      
      []
    rescue CsvParser::Error => e
      raise Error, e.message
    rescue ArgumentError => e
      raise Error, e.message
    end

  end
end
