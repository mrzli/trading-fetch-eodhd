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
    end
  end
end
