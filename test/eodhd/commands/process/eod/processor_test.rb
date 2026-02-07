# frozen_string_literal: true

require "ostruct"

require_relative "../../../../test_helper"

describe Eodhd::Commands::Process::Eod::Processor do
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

    # Raw split objects with date and factor fields
    splits = [
      OpenStruct.new(date: Date.new(2000, 6, 21), factor: 2.0),
      OpenStruct.new(date: Date.new(2014, 6, 9), factor: 7.0),
      OpenStruct.new(date: Date.new(2024, 1, 10), factor: 4.0 )
    ]

    # Raw dividend objects with date and unadjusted_value fields
    dividends = [
      OpenStruct.new(date: Date.new(2024, 1, 11), unadjusted_value: 1.4)
    ]

    processor = Eodhd::Commands::Process::Eod::Processor.new(log: Logging::NullLogger.new)
    out = processor.process_csv(raw_csv, splits, dividends)

    # Dividend on 2024-01-11 uses previous close (2024-01-10 close=7)
    # Multiplier = (7 - 1.4) / 7 = 0.8
    # Rows before 2024-01-11 get multiplied by 0.8
    expected = <<~CSV
      Date,Open,High,Low,Close,Volume
      1999-11-18,0.8,0.8,0.8,0.8,560
      1999-11-19,1.6,1.6,1.6,1.6,1120
      2000-06-21,0.8,0.8,0.8,0.8,840
      2000-06-22,1.6,1.6,1.6,1.6,1120
      2014-06-09,8.0,8.0,8.0,8.0,200
      2014-06-10,4.0,4.0,4.0,4.0,240
      2024-01-10,5.6,5.6,5.6,5.6,1
      2024-01-11,8.0,8.0,8.0,8.0,2
    CSV

    assert_equal expected, out
  end
end
