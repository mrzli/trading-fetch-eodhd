# frozen_string_literal: true

require "csv"
require "date"

require_relative "../../parsing/csv_parser"
require_relative "split_processor"

module Eodhd
  class IntradayProcessor
    OUTPUT_HEADERS = ["Timestamp", "Datetime", "Open", "High", "Low", "Close", "Volume"].freeze

    class Error < StandardError; end

    def initialize(log:)
      @log = log
    end

    def process_csv_files!(raw_csv_files, splits)
      unless raw_csv_files.is_a?(Array)
        raise ArgumentError, "raw_csv_files must be an Array"
      end

      inputs = raw_csv_files.drop(70).map.with_index do |raw_csv, index|
        parsed = CsvParser.parse_intraday!(raw_csv)
        if parsed.empty?
          @log.info("Skipped empty intraday CSV file #{index + 1} with size #{raw_csv.bytesize} bytes")
          next
        end

        first = parsed.first
        last = parsed.last
        @log.info("Parsed intraday CSV file #{index + 1} for interval #{first[:datetime]} - #{last[:datetime]} with size #{raw_csv.bytesize} bytes")

        parsed
      end

      merged_rows = []
      inputs.each do |input|
        next if input.empty?

        if merged_rows.empty?
          merged_rows = input
          next
        end

        merge_in_place!(merged_rows, input)
      end

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

    private

    def merge_in_place!(merged_rows, next_rows)
      return if next_rows.empty?
      return merged_rows.concat(next_rows) if merged_rows.empty?

      next_first = next_rows.first[:timestamp]
      merged_last = merged_rows.last[:timestamp]

      if next_first > merged_last
        merged_rows.concat(next_rows)
        return
      end

      idx = lower_bound_timestamp(merged_rows, next_first)
      merged_rows.slice!(idx, merged_rows.length - idx)
      merged_rows.concat(next_rows)
    end

    def lower_bound_timestamp(rows, timestamp)
      lo = 0
      hi = rows.length

      while lo < hi
        mid = (lo + hi) / 2
        if rows[mid][:timestamp] < timestamp
          lo = mid + 1
        else
          hi = mid
        end
      end

      lo
    end
  end
end
