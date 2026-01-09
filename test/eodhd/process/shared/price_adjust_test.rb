
# frozen_string_literal: true

require_relative "../../../test_helper"

require "bigdecimal"
require "date"

require_relative "../../../../lib/eodhd/parsing/splits_parser"
require_relative "../../../../lib/eodhd/process/shared/split_processor"
require_relative "../../../../lib/eodhd/process/shared/price_adjust"

describe Eodhd::PriceAdjust do
  it "returns rows unchanged when no splits" do
    rows = [
      { timestamp: Time.utc(2024, 1, 10).to_i, date: Date.new(2024, 1, 10), open: BigDecimal("10"), high: BigDecimal("11"), low: BigDecimal("9"), close: BigDecimal("10.5"), volume: 100 }
    ]

    adjusted = Eodhd::PriceAdjust.apply(rows, [])

    _(adjusted).must_equal rows
  end

  it "applies cumulative split factors to prior rows" do
    rows = [
      drow("1999-11-18", "56", "56", "56", "56", 10),
      drow("1999-11-19", "112", "112", "112", "112", 20),
      drow("2000-06-21", "28", "28", "28", "28", 30),
      drow("2000-06-22", "56", "56", "56", "56", 40),
      drow("2014-06-09", "40", "40", "40", "40", 50),
      drow("2014-06-10", "20", "20", "20", "20", 60),
      drow("2024-01-10", "7", "7", "7", "7", 1),
      drow("2024-01-11", "8", "8", "8", "8", 2)
    ]

    splits_json = <<~JSON
      [
        {"date":"2000-06-21","split":"2.000000/1.000000"},
        {"date":"2014-06-09","split":"7.000000/1.000000"},
        {"date":"2024-01-10","split":"4.000000/1.000000"}
      ]
    JSON

    raw_splits = Eodhd::SplitsParser.parse_splits(splits_json)
    segments = Eodhd::SplitProcessor.process(raw_splits)

    adjusted = Eodhd::PriceAdjust.apply(rows, segments)

    expected = [
      drow("1999-11-18", "1.0", "1.0", "1.0", "1.0", 560),
      drow("1999-11-19", "2.0", "2.0", "2.0", "2.0", 1120),
      drow("2000-06-21", "1.0", "1.0", "1.0", "1.0", 840),
      drow("2000-06-22", "2.0", "2.0", "2.0", "2.0", 1120),
      drow("2014-06-09", "10.0", "10.0", "10.0", "10.0", 200),
      drow("2014-06-10", "5.0", "5.0", "5.0", "5.0", 240),
      drow("2024-01-10", "7.0", "7.0", "7.0", "7.0", 1),
      drow("2024-01-11", "8.0", "8.0", "8.0", "8.0", 2)
    ]

    _(adjusted).must_equal expected
  end

  def drow(date_str, open, high, low, close, volume)
    date = Date.parse(date_str)
    {
      timestamp: date.to_time.to_i,
      date: date,
      open: BigDecimal(open),
      high: BigDecimal(high),
      low: BigDecimal(low),
      close: BigDecimal(close),
      volume: volume
    }
  end
end
