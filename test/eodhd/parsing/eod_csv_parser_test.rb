# frozen_string_literal: true

require_relative "../../test_helper"

require "date"
require_relative "../../../lib/eodhd/parsing/eod_csv_parser"

describe Eodhd::Parsing::EodCsvParser do
  it "parses EOD rows" do
    raw = <<~CSV
      Date,Open,High,Low,Close,Adjusted_close,Volume
      2024-01-10,10,11,9,10.5,10.3,1000
      2024-01-11,20.1,21.2,19.9,20.5,20.5,2000
      ,1,1,1,1,1,1
    CSV

    result = Eodhd::Parsing::EodCsvParser.parse(raw)

    expected = [
      {
        timestamp: Date.new(2024, 1, 10).to_time.to_i,
        date: Date.new(2024, 1, 10),
        open: 10.0,
        high: 11.0,
        low: 9.0,
        close: 10.5,
        volume: 1000
      },
      {
        timestamp: Date.new(2024, 1, 11).to_time.to_i,
        date: Date.new(2024, 1, 11),
        open: 20.1,
        high: 21.2,
        low: 19.9,
        close: 20.5,
        volume: 2000
      }
    ]

    assert_equal expected, result
  end

  it "raises on missing columns" do
    raw = <<~CSV
      Date,Open,High,Low,Close,Volume
      2024-01-10,10,11,9,10.5,1000
    CSV

    err = _ { Eodhd::Parsing::EodCsvParser.parse(raw) }.must_raise(Eodhd::Parsing::EodCsvParser::Error)
    _(err.message).must_match(/Missing required columns/i)
  end

  it "raises on invalid data" do
    raw = <<~CSV
      Date,Open,High,Low,Close,Adjusted_close,Volume
      not-a-date,10,11,9,10.5,10.3,1000
    CSV

    err = _ { Eodhd::Parsing::EodCsvParser.parse(raw) }.must_raise(Eodhd::Parsing::EodCsvParser::Error)
    _(err.message).must_match(/Invalid data/i)
  end
end
