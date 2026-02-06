# frozen_string_literal: true

require "csv"

module Eodhd
  module Parsing
    class IntradayCsvParser
      class Error < StandardError; end

      class << self
        def parse(raw_csv)
          csv = CSV.parse(raw_csv, headers: true)
          validate_headers(csv.headers)

          csv.map do |row|
            begin
              timestamp = Integer(row["Timestamp"])
              gmtoffset = Integer(row["Gmtoffset"])
              datetime = row["Datetime"]
              open = Float(row["Open"])
              high = Float(row["High"])
              low = Float(row["Low"])
              close = Float(row["Close"])
              volume_str = row["Volume"].to_s
              volume = volume_str != "" ? Integer(volume_str) : 0
            rescue TypeError => e
              raise Error, "Invalid data in row '#{row["Datetime"]}': #{e.message}"
            end

            if gmtoffset != 0
              raise Error, "Only Gmtoffset=0 is supported for now (got #{gmtoffset})"
            end

            {
              timestamp: timestamp,
              gmtoffset: gmtoffset,
              datetime: datetime,
              open: open,
              high: high,
              low: low,
              close: close,
              volume: volume
            }
          end
        rescue ArgumentError => e
          raise Error, e.message
        end

        private

        def validate_headers(headers)
          headers = headers.compact.map(&:to_s)
          required = ["Timestamp", "Gmtoffset", "Datetime", "Open", "High", "Low", "Close", "Volume"]

          missing = required.reject { |h| headers.include?(h) }
          return if missing.empty?

          raise Error, "Missing required columns: #{missing.join(", ")}" 
        end
      end
    end
  end
end
