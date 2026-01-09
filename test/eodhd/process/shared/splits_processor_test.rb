# frozen_string_literal: true

require_relative "../../../test_helper"

require_relative "../../../../lib/eodhd/parsing/splits_parser"
require_relative "../../../../lib/eodhd/process/shared/splits_processor"

describe Eodhd::SplitsProcessor do
  it "returns empty array for nil splits" do
    result = Eodhd::SplitsProcessor.process(nil)
    assert_equal [], result
  end

  it "returns empty array for empty splits" do
    result = Eodhd::SplitsProcessor.process([])
    assert_equal [], result
  end

  it "processes single split" do
    splits_json = <<~JSON
      [
        {"date":"2014-11-03","split":"1398.000000/1000.000000"}
      ]
    JSON

    splits = Eodhd::SplitsParser.parse_splits(splits_json)
    result = Eodhd::SplitsProcessor.process(splits)

    expected = [
      {
        timestamp: Date.new(2014, 11, 3).to_time.to_i,
        factor: Rational(1398, 1000)
      }
    ]

    assert_equal expected, result
  end

  it "processes multiple splits with cumulative factors" do
    splits_json = <<~JSON
      [
        {"date":"2000-06-21","split":"2.000000/1.000000"},
        {"date":"2014-06-09","split":"7.000000/1.000000"},
        {"date":"2024-01-10","split":"4.000000/1.000000"}
      ]
    JSON

    splits = Eodhd::SplitsParser.parse_splits(splits_json)
    result = Eodhd::SplitsProcessor.process(splits)

    expected = [
      { timestamp: Date.new(2000, 6, 21).to_time.to_i, factor: Rational(56, 1) },
      { timestamp: Date.new(2014, 6, 9).to_time.to_i, factor: Rational(28, 1) },
      { timestamp: Date.new(2024, 1, 10).to_time.to_i, factor: Rational(4, 1) }
    ]

    assert_equal expected, result
  end

  it "handles fractional split ratios" do
    splits_json = <<~JSON
      [
        {"date":"2020-01-01","split":"3.000000/2.000000"},
        {"date":"2021-01-01","split":"5.000000/4.000000"}
      ]
    JSON

    splits = Eodhd::SplitsParser.parse_splits(splits_json)
    result = Eodhd::SplitsProcessor.process(splits)

    expected = [
      { timestamp: Date.new(2020, 1, 1).to_time.to_i, factor: Rational(15, 8) },
      { timestamp: Date.new(2021, 1, 1).to_time.to_i, factor: Rational(5, 4) }
    ]

    assert_equal expected, result
  end
end
