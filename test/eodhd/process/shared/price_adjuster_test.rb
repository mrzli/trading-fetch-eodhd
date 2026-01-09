# frozen_string_literal: true

require_relative "../../../test_helper"

require "date"
require_relative "../../../../lib/eodhd/process/shared/price_adjuster"

describe Eodhd::PriceAdjuster do
  it "adjusts prices by dividing and volume by multiplying" do
    factor = Rational(56, 1)

    _(Eodhd::PriceAdjuster.adjust_price(BigDecimal(56), factor)).must_equal BigDecimal(1)
    _(Eodhd::PriceAdjuster.adjust_price(BigDecimal(112), factor)).must_equal BigDecimal(2)
    _(Eodhd::PriceAdjuster.adjust_volume(10, factor)).must_equal 560
    _(Eodhd::PriceAdjuster.adjust_volume(20, factor)).must_equal 1120
  end
end
