# frozen_string_literal: true

require_relative "../../test_helper"

require_relative "../../../lib/eodhd/parsing/splits_parser"
require_relative "../../../lib/eodhd/process/eod_processor"

describe Eodhd::EodProcessor do
  it "omits Adjusted_close and split-adjusts prior rows" do
    raw_csv = <<~CSV
      Date,Open,High,Low,Close,Adjusted_close,Volume
      1999-11-18,56,56,56,56,0,10
      1999-11-19,112,112,112,112,0,20
      2000-06-21,28,28,28,28,0,30
      2000-06-22,56,56,56,56,0,40
      2014-06-09,40,40,40,40,0,50
      2014-06-10,20,20,20,20,0,60
      2024-01-10,7,7,7,7,0,1
      2024-01-11,8,8,8,8,0,2
    CSV

    splits_json = <<~JSON
      [
        {"date":"2000-06-21","split":"2.000000/1.000000"},
        {"date":"2014-06-09","split":"7.000000/1.000000"},
        {"date":"2024-01-10","split":"4.000000/1.000000"}
      ]
    JSON

    splits = Eodhd::SplitsParser.parse_splits!(splits_json)
    processor = Eodhd::EodProcessor.new(log: Eodhd::NullLogger.new)
    out = processor.process_csv!(raw_csv, splits)

    expected = <<~CSV
      Date,Open,High,Low,Close,Volume
      1999-11-18,1.0,1.0,1.0,1.0,560
      1999-11-19,2.0,2.0,2.0,2.0,1120
      2000-06-21,1.0,1.0,1.0,1.0,840
      2000-06-22,2.0,2.0,2.0,2.0,1120
      2014-06-09,10.0,10.0,10.0,10.0,200
      2014-06-10,5.0,5.0,5.0,5.0,240
      2024-01-10,7.0,7.0,7.0,7.0,1
      2024-01-11,8.0,8.0,8.0,8.0,2
    CSV

    assert_equal expected, out
  end
end
