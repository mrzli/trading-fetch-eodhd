# frozen_string_literal: true

require_relative "../../test_helper"

require_relative "../../../lib/eodhd/parsing/intraday_csv_parser"

describe Eodhd::IntradayCsvParser do
  it "parses intraday rows" do
    raw = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      100,0,"2000-01-01 00:00:00",1,2,3,4,10
      200,0,"2000-01-01 00:01:00",5.5,6.5,4.5,5.0,20
    CSV

    result = Eodhd::IntradayCsvParser.parse(raw)

    expected = [
      {
        timestamp: 100,
        datetime: "2000-01-01 00:00:00",
        open: 1.0,
        high: 2.0,
        low: 3.0,
        close: 4.0,
        volume: 10
      },
      {
        timestamp: 200,
        datetime: "2000-01-01 00:01:00",
        open: 5.5,
        high: 6.5,
        low: 4.5,
        close: 5.0,
        volume: 20
      }
    ]

    assert_equal expected, result
  end

  it "raises on non-zero gmtoffset" do
    raw = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      100,3600,"2000-01-01 00:00:00",1,2,3,4,10
    CSV

    err = _ { Eodhd::IntradayCsvParser.parse(raw) }.must_raise(Eodhd::IntradayCsvParser::Error)
    _(err.message).must_match(/Gmtoffset=0/i)
  end

  it "raises on missing columns" do
    raw = <<~CSV
      Timestamp,Datetime,Open,High,Low,Close,Volume
      100,"2000-01-01 00:00:00",1,2,3,4,10
    CSV

    err = _ { Eodhd::IntradayCsvParser.parse(raw) }.must_raise(Eodhd::IntradayCsvParser::Error)
    _(err.message).must_match(/Missing required columns/i)
  end
end
