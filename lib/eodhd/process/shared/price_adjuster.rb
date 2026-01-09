# frozen_string_literal: true

require "bigdecimal"
require "date"

require_relative "../../../util"

module Eodhd
  class PriceAdjuster
    class Error < StandardError; end

    class << self
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
    end
  end
end
