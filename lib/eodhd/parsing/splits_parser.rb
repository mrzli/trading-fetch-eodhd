# frozen_string_literal: true

require "date"
require "json"

require_relative "../../util"

module Eodhd
  class SplitsParser
    class Error < StandardError; end

    Split = Data.define(:date, :factor)

    class << self
      def parse_splits(splits_json, sorted: true)
        splits_json = splits_json.to_s
        return [] if splits_json.strip.empty?

        parsed = JSON.parse(splits_json)
        unless parsed.is_a?(Array)
          raise Error, "splits_json must be a JSON array"
        end

        splits = parsed.map do |entry|
          date_str = entry.is_a?(Hash) ? entry["date"] : nil
          split_str = entry.is_a?(Hash) ? entry["split"] : nil

          date_str = Validate.required_string("split.date", date_str)
          split_str = Validate.required_string("split.split", split_str)

          Split.new(
            date: Date.iso8601(date_str),
            factor: parse_split_factor(split_str)
          )
        end

        splits.sort_by!(&:date) unless sorted
        splits
      rescue JSON::ParserError => e
        raise Error, "Invalid splits_json: #{e.message}"
      end

      private

      def parse_split_factor(split_str)
        parts = split_str.split("/")
        unless parts.length == 2
          raise Error, "Invalid split format: #{split_str.inspect}"
        end

        numerator = Rational(parts[0])
        denominator = Rational(parts[1])
        if numerator <= 0 || denominator <= 0
          raise Error, "Invalid split ratio: #{split_str.inspect}"
        end

        numerator / denominator
      rescue ArgumentError
        raise Error, "Invalid split ratio: #{split_str.inspect}"
      end
    end
  end
end
