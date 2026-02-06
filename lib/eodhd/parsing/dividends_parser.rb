# frozen_string_literal: true

require "date"
require "json"

require_relative "../../util"

module Eodhd
  module Parsing
    class DividendsParser
      class Error < StandardError; end

      Dividend = Data.define(
        :date,
        :declaration_date,
        :record_date,
        :payment_date,
        :period,
        :value,
        :unadjusted_value,
        :currency
      )

      class << self
        def parse(dividends_json, sorted: true)
          dividends_json = dividends_json.to_s
          return [] if dividends_json.strip.empty?

          parsed = JSON.parse(dividends_json)
          unless parsed.is_a?(Array)
            raise Error, "dividends_json must be a JSON array"
          end

          dividends = parsed.map do |entry|
            unless entry.is_a?(Hash)
              raise Error, "Each dividend entry must be a hash"
            end

            date_str = Util::Validate.required_string("dividend.date", entry["date"])

            Dividend.new(
              date: parse_date(date_str),
              declaration_date: parse_optional_date(entry["declarationDate"]),
              record_date: parse_optional_date(entry["recordDate"]),
              payment_date: parse_optional_date(entry["paymentDate"]),
              period: entry["period"],
              value: parse_float_value("dividend.value", entry["value"]),
              unadjusted_value: parse_float_value("dividend.unadjustedValue", entry["unadjustedValue"]),
              currency: Util::Validate.required_string("dividend.currency", entry["currency"])
            )
          rescue ArgumentError => e
            raise Error, e.message
          end

          dividends.sort_by!(&:date) unless sorted
          dividends
        rescue JSON::ParserError => e
          raise Error, "Invalid dividends_json: #{e.message}"
        end

        private

        def parse_date(date_str)
          Date.iso8601(date_str)
        rescue Date::Error => e
          raise Error, "Invalid date format: #{date_str.inspect} - #{e.message}"
        end

        def parse_optional_date(date_str)
          return nil if date_str.nil? || date_str.to_s.strip.empty?

          Date.iso8601(date_str)
        rescue Date::Error => e
          raise Error, "Invalid date format: #{date_str.inspect} - #{e.message}"
        end

        def parse_float_value(field_name, value)
          if value.nil?
            raise Error, "#{field_name} is required"
          end

          Float(value)
        rescue ArgumentError, TypeError => e
          raise Error, "Invalid #{field_name}: #{value.inspect} - #{e.message}"
        end
      end
    end
  end
end
