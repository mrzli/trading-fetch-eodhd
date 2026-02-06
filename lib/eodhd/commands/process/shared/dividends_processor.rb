# frozen_string_literal: true

require_relative "../../../../util"

module Eodhd
  class DividendsProcessor
    class Error < StandardError; end

    class << self
      # Builds dividend adjustment segments using unadjusted price data.
      #
      # dividends: array of DividendsParser::Dividend objects (sorted or unsorted)
      # data: array of hashes with at least :timestamp and :close (unadjusted prices)
      #
      # Returns array of {timestamp:, multiplier:} sorted by timestamp. Each multiplier
      # is cumulative from that dividend forward.
      def process(dividends, data)
        return [] if dividends.nil? || dividends.empty?

        data ||= []
        raise Error, "data must not be empty" if data.empty?

        sorted_data = data.sort_by { |row| row.fetch(:timestamp) }
        sorted_dividends = dividends.sort_by(&:date)

        events = sorted_dividends.filter_map do |dividend|
          ts = dividend.date.to_time.to_i
          idx = Util::BinarySearch.last_lt(sorted_data, ts) { |row| row[:timestamp] }

          next if idx.nil?

          prev_close = sorted_data[idx][:close]
          raise Error, "Missing close price before #{dividend.date}" if prev_close.nil?

          prev_close = Float(prev_close)
          if prev_close <= 0.0
            raise Error, "Previous close must be positive before #{dividend.date} (got #{prev_close})"
          end

          dividend_value = Float(dividend.unadjusted_value)
          multiplier = (prev_close - dividend_value) / prev_close

          if multiplier <= 0.0
            raise Error, "Dividend on #{dividend.date} is too large for previous close #{prev_close}"
          end

          { timestamp: ts, multiplier: multiplier }
        end

        cumulative = 1.0
        segments = []

        events.reverse_each do |event|
          cumulative *= event[:multiplier]
          segments << { timestamp: event[:timestamp], multiplier: cumulative }
        end

        segments.reverse
      end
    end
  end
end
