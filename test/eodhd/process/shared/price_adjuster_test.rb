# frozen_string_literal: true

require_relative "../../../test_helper"

require "date"
require_relative "../../../../lib/eodhd/process/shared/price_adjuster"

describe Eodhd::PriceAdjuster do
  def parse_splits(json)
    Eodhd::SplitsParser.parse_splits!(json)
  end

  it "computes cumulative split factors with strict split-date semantics" do
    splits = parse_splits(<<~JSON)
      [
        {"date":"2000-06-21","split":"2.000000/1.000000"},
        {"date":"2014-06-09","split":"7.000000/1.000000"},
        {"date":"2024-01-10","split":"4.000000/1.000000"}
      ]
    JSON

    _(Eodhd::PriceAdjuster.cumulative_split_factor_for_date(Date.iso8601("1999-11-18"), splits)).must_equal Rational(56, 1)

    # On the split day itself, that split does NOT apply; only later splits.
    _(Eodhd::PriceAdjuster.cumulative_split_factor_for_date(Date.iso8601("2000-06-21"), splits)).must_equal Rational(28, 1)
    _(Eodhd::PriceAdjuster.cumulative_split_factor_for_date(Date.iso8601("2014-06-09"), splits)).must_equal Rational(4, 1)

    # On latest split day, nothing later applies.
    _(Eodhd::PriceAdjuster.cumulative_split_factor_for_date(Date.iso8601("2024-01-10"), splits)).must_equal Rational(1, 1)

    # After the latest split day, still nothing applies.
    _(Eodhd::PriceAdjuster.cumulative_split_factor_for_date(Date.iso8601("2024-01-11"), splits)).must_equal Rational(1, 1)
  end

  it "adjusts prices by dividing and volume by multiplying" do
    factor = Rational(56, 1)

    _(Eodhd::PriceAdjuster.adjust_price("56", factor)).must_equal "1.0"
    _(Eodhd::PriceAdjuster.adjust_price("112", factor)).must_equal "2.0"

    _(Eodhd::PriceAdjuster.adjust_volume("10", factor)).must_equal "560"
    _(Eodhd::PriceAdjuster.adjust_volume("20", factor)).must_equal "1120"
  end

  it "raises on invalid volume" do
    err = _(-> { Eodhd::PriceAdjuster.adjust_volume("not-an-int", Rational(2, 1)) }).must_raise(Eodhd::PriceAdjuster::Error)
    _(err.message).must_match(/Invalid volume/i)
  end
end
