# frozen_string_literal: true

require_relative "../../../test_helper"

require "date"

require_relative "../../../../lib/eodhd/parsing/dividends_parser"
require_relative "../../../../lib/eodhd/process/shared/dividends_processor"

describe Eodhd::DividendsProcessor do
  it "returns empty array for nil dividends" do
    result = Eodhd::DividendsProcessor.process(nil, [])
    _(result).must_equal []
  end

  it "returns empty array for empty dividends" do
    result = Eodhd::DividendsProcessor.process([], [])
    _(result).must_equal []
  end

  it "computes multiplier using previous close" do
    dividends = [dividend("2024-01-11", 1.0)]
    data = [row("2024-01-12", 104), row("2024-01-10", 100), row("2024-01-11", 102)]

    result = Eodhd::DividendsProcessor.process(dividends, data)

    expected = [
      { timestamp: date_to_ts("2024-01-11"), multiplier: 0.99 }
    ]

    _(result).must_equal expected
  end

  it "calculates cumulative multipliers for multiple dividends" do
    dividends = [
      dividend("2024-01-10", 2.0),
      dividend("2024-01-12", 3.0)
    ]

    data = [
      row("2024-01-11", 120),
      row("2024-01-09", 100),
      row("2024-01-08", 90),
      row("2024-01-12", 130),
      row("2024-01-10", 110)
    ]

    result = Eodhd::DividendsProcessor.process(dividends, data)

    m1 = (100.0 - 2.0) / 100.0
    m2 = (120.0 - 3.0) / 120.0

    expected = [
      { timestamp: date_to_ts("2024-01-10"), multiplier: m1 * m2 },
      { timestamp: date_to_ts("2024-01-12"), multiplier: m2 }
    ]

    _(result).must_equal expected
  end

  it "raises when no previous price is available" do
    dividends = [dividend("2024-01-10", 1.0)]
    data = [row("2024-01-10", 100)]

    err = _(-> { Eodhd::DividendsProcessor.process(dividends, data) }).must_raise(Eodhd::DividendsProcessor::Error)
    _(err.message).must_match(/No price data before dividend date/)
  end

  it "raises when previous close is non-positive" do
    dividends = [dividend("2024-01-11", 1.0)]
    data = [row("2024-01-10", 0)]

    err = _(-> { Eodhd::DividendsProcessor.process(dividends, data) }).must_raise(Eodhd::DividendsProcessor::Error)
    _(err.message).must_match(/must be positive/)
  end

  it "raises when dividend wipes out or exceeds previous close" do
    dividends = [dividend("2024-01-11", 5.0)]
    data = [row("2024-01-10", 5.0)]

    err = _(-> { Eodhd::DividendsProcessor.process(dividends, data) }).must_raise(Eodhd::DividendsProcessor::Error)
    _(err.message).must_match(/too large/)
  end

  def row(date_str, close)
    ts = date_to_ts(date_str)
    { timestamp: ts, close: Float(close) }
  end

  def dividend(date_str, unadjusted_value)
    Eodhd::DividendsParser::Dividend.new(
      date: Date.iso8601(date_str),
      declaration_date: nil,
      record_date: nil,
      payment_date: nil,
      period: nil,
      value: unadjusted_value,
      unadjusted_value: unadjusted_value,
      currency: "USD"
    )
  end

  def date_to_ts(date_str)
    Date.iso8601(date_str).to_time.to_i
  end
end
