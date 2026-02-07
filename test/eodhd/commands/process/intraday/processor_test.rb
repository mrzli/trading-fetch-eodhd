# frozen_string_literal: true

require "ostruct"

require_relative "../../../../test_helper"

require_relative "../../../../../lib/eodhd/commands/process/intraday/processor"

describe Eodhd::Commands::Process::Intraday::Processor do
  it "processes multiple CSV inputs with splits and dividends" do
    # First CSV file with earlier data
    raw_csv_1 = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      946684800,0,2000-01-01 00:00:00,56,56,56,56,10
      946688400,0,2000-01-01 01:00:00,112,112,112,112,20
    CSV

    # Second CSV file with later data
    raw_csv_2 = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      1402358400,0,2014-06-10 00:00:00,20,20,20,20,60
      1705708800,0,2024-01-20 00:00:00,7,7,7,7,1
      1705712400,0,2024-01-20 01:00:00,8,8,8,8,2
    CSV

    # Raw split objects with date and factor fields
    splits = [
      OpenStruct.new(date: Date.new(2000, 6, 21), factor: 2.0),
      OpenStruct.new(date: Date.new(2014, 6, 9), factor: 7.0),
      OpenStruct.new(date: Date.new(2024, 1, 10), factor: 4.0)
    ]

    # Raw dividend objects with date and unadjusted_value fields
    dividends = [
      OpenStruct.new(date: Date.new(2024, 1, 21), unadjusted_value: 1.4)
    ]

    processor = Eodhd::Commands::Process::Intraday::Processor.new(log: Logging::NullLogger.new)
    result = processor.process_csv_list([raw_csv_1, raw_csv_2], splits, dividends)

    # Should have data split by month
    assert_equal 3, result.size

    # First month: 2000-01
    first_month = result[0]
    assert_equal "2000-01", first_month[:key].to_s

    # Dividend on 2024-01-21 uses previous close (2024-01-20 01:00:00 close=8)
    # Multiplier = (8 - 1.4) / 8 = 0.825
    # All rows before 2024-01-21 get multiplied by 0.825
    # Also, split adjustments:
    # - Rows before 2000-06-21: cumulative factor = 2.0 * 7.0 * 4.0 = 56.0
    # - Price = original / 56.0, Volume = original * 56
    # - Then multiply by dividend factor 0.825
    # So: 56/56*0.825 = 0.825, 112/56*0.825 = 1.65
    expected_first = <<~CSV
      Timestamp,Datetime,Open,High,Low,Close,Volume
      946684800,2000-01-01 00:00:00,0.825,0.825,0.825,0.825,560
      946688400,2000-01-01 01:00:00,1.65,1.65,1.65,1.65,1120
    CSV

    assert_equal expected_first, first_month[:csv]

    # Second month: 2014-06
    second_month = result[1]
    assert_equal "2014-06", second_month[:key].to_s

    # This row (2014-06-10) is after 2014-06-09 split but before 2024-01-10 split
    # Cumulative factor = 4.0 (only the 2024 split applies)
    # Price = 20 / 4.0 * 0.825 = 4.125, Volume = 60 * 4 = 240
    expected_second = <<~CSV
      Timestamp,Datetime,Open,High,Low,Close,Volume
      1402358400,2014-06-10 00:00:00,4.125,4.125,4.125,4.125,240
    CSV

    assert_equal expected_second, second_month[:csv]

    # Third month: 2024-01
    third_month = result[2]
    assert_equal "2024-01", third_month[:key].to_s

    # These rows (2024-01-20) are after all splits but before dividend on 2024-01-21
    # No split factor applies (or factor = 1.0)
    # Dividend multiplier = 0.825
    # Price = original * 0.825
    expected_third = <<~CSV
      Timestamp,Datetime,Open,High,Low,Close,Volume
      1705708800,2024-01-20 00:00:00,5.775,5.775,5.775,5.775,1
      1705712400,2024-01-20 01:00:00,6.6,6.6,6.6,6.6,2
    CSV

    assert_equal expected_third, third_month[:csv]
  end

  it "handles empty CSV files in the list" do
    raw_csv_1 = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      946684800,0,2000-01-01 00:00:00,10,10,10,10,100
    CSV

    # Empty CSV with only headers
    raw_csv_2 = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
    CSV

    raw_csv_3 = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      946688400,0,2000-01-01 01:00:00,20,20,20,20,200
    CSV

    processor = Eodhd::Commands::Process::Intraday::Processor.new(log: Logging::NullLogger.new)
    result = processor.process_csv_list([raw_csv_1, raw_csv_2, raw_csv_3], [], [])

    # Should merge the non-empty CSVs
    assert_equal 1, result.size
    
    expected = <<~CSV
      Timestamp,Datetime,Open,High,Low,Close,Volume
      946684800,2000-01-01 00:00:00,10.0,10.0,10.0,10.0,100
      946688400,2000-01-01 01:00:00,20.0,20.0,20.0,20.0,200
    CSV

    assert_equal expected, result[0][:csv]
  end

  it "formats prices with correct decimal places" do
    raw_csv = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      946684800,0,2000-01-01 00:00:00,1.123456789,2.987654321,0.555555555,1.999999999,100
    CSV

    processor = Eodhd::Commands::Process::Intraday::Processor.new(log: Logging::NullLogger.new)
    result = processor.process_csv_list([raw_csv], [], [])

    # Should round to OUTPUT_DECIMALS (6)
    expected = <<~CSV
      Timestamp,Datetime,Open,High,Low,Close,Volume
      946684800,2000-01-01 00:00:00,1.123457,2.987654,0.555556,2.0,100
    CSV

    assert_equal expected, result[0][:csv]
  end

  it "raises error for non-array input" do
    processor = Eodhd::Commands::Process::Intraday::Processor.new(log: Logging::NullLogger.new)
    
    err = _ { processor.process_csv_list("not an array", [], []) }.must_raise(Eodhd::Commands::Process::Intraday::Processor::Error)
    _(err.message).must_match(/must be an Array/i)
  end

  it "handles splits only" do
    raw_csv = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      946684800,0,2000-01-01 00:00:00,100,100,100,100,10
      946771200,0,2000-01-02 00:00:00,50,50,50,50,20
    CSV

    splits = [
      OpenStruct.new(date: Date.new(2000, 6, 21), factor: 2.0)
    ]

    processor = Eodhd::Commands::Process::Intraday::Processor.new(log: Logging::NullLogger.new)
    result = processor.process_csv_list([raw_csv], splits, [])

    # Both rows are before the split on 2000-06-21
    # Split factor = 2.0
    # Price = original / 2.0, Volume = original * 2
    expected = <<~CSV
      Timestamp,Datetime,Open,High,Low,Close,Volume
      946684800,2000-01-01 00:00:00,50.0,50.0,50.0,50.0,20
      946771200,2000-01-02 00:00:00,25.0,25.0,25.0,25.0,40
    CSV

    assert_equal expected, result[0][:csv]
  end

  it "handles dividends only" do
    raw_csv = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      946684800,0,2000-01-01 00:00:00,100,100,100,100,10
      946771200,0,2000-01-02 00:00:00,100,100,100,100,20
    CSV

    dividends = [
      OpenStruct.new(date: Date.new(2000, 1, 2), unadjusted_value: 20.0)
    ]

    processor = Eodhd::Commands::Process::Intraday::Processor.new(log: Logging::NullLogger.new)
    result = processor.process_csv_list([raw_csv], [], dividends)

    # Dividend on 2000-01-02 uses previous close (2000-01-01 close=100)
    # Multiplier = (100 - 20) / 100 = 0.8
    # Row before 2000-01-02 gets multiplied by 0.8
    expected = <<~CSV
      Timestamp,Datetime,Open,High,Low,Close,Volume
      946684800,2000-01-01 00:00:00,80.0,80.0,80.0,80.0,10
      946771200,2000-01-02 00:00:00,100.0,100.0,100.0,100.0,20
    CSV

    assert_equal expected, result[0][:csv]
  end
end
