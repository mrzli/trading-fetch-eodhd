# frozen_string_literal: true

require "bigdecimal"
require "date"

require_relative "../../../util"

module Eodhd
  class PriceAdjuster
    class Error < StandardError; end

    class << self
      # Referent price is the latest price.
      # Rows strictly before a split date must be adjusted by the product of all
      # split factors whose date is after the row date.
      def cumulative_split_factor_for_date(date, splits)
        splits ||= []
        return Rational(1, 1) if splits.empty?

        date = Date.iso8601(date.to_s) unless date.is_a?(Date)

        # Find the first split whose date is strictly greater than the row date.
        idx = upper_bound_split_date(splits, date)
        return Rational(1, 1) if idx >= splits.length

        # Product of all split factors from idx..end.
        factor = Rational(1, 1)
        (idx...splits.length).each do |i|
          factor *= splits[i].factor
        end
        factor
      end

      def adjust_price(value, factor)
        value / factor
      end

      def adjust_volume(value, factor)
        (value * factor).to_i
      end

      private

      def upper_bound_split_date(splits, date)
        lo = 0
        hi = splits.length

        while lo < hi
          mid = (lo + hi) / 2
          if splits[mid].date <= date
            lo = mid + 1
          else
            hi = mid
          end
        end

        lo
      end

      def rational_to_bigdecimal(r)
        BigDecimal(r.numerator.to_s) / BigDecimal(r.denominator.to_s)
      end
    end
  end
end
