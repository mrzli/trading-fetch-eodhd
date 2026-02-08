# frozen_string_literal: true

require "ostruct"

require_relative "../../../../../test_helper"

describe Eodhd::Commands::Process::Subcommands::Intraday::Processor do
  it "processes single CSV with splits and dividends" do
    raw_csv = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      946684800,0,2000-01-01 00:00:00,56,56,56,56,10
      946688400,0,2000-01-01 01:00:00,112,112,112,112,20
      1402358400,0,2014-06-10 00:00:00,20,20,20,20,60
    CSV

    # Raw split objects with date and factor fields
    splits = [
      OpenStruct.new(date: Date.new(2000, 6, 21), factor: 2.0),
      OpenStruct.new(date: Date.new(2014, 6, 9), factor: 7.0)
    ]

    # Raw dividend objects with date and unadjusted_value fields
    dividends = [
      OpenStruct.new(date: Date.new(2014, 6, 11), unadjusted_value: 0.7)
    ]

    processor = Eodhd::Commands::Process::Subcommands::Intraday::Processor.new(log: Logging::NullLogger.new)
    result_csv = processor.process_csv(raw_csv, splits, dividends)

    refute_nil result_csv
    lines = result_csv.split("\n")
    
    # Should have header + 3 data rows
    assert_equal 4, lines.size
    
    # Check header
    assert_equal "Timestamp,Datetime,Open,High,Low,Close,Volume", lines[0]
    
    # Parse and verify data rows
    data_lines = lines[1..3]
    
    # Verify timestamps are preserved
    assert_match(/^946684800,/, data_lines[0])
    assert_match(/^946688400,/, data_lines[1])
    assert_match(/^1402358400,/, data_lines[2])
    
    # Verify datetime is preserved
    assert_match(/,2000-01-01 00:00:00,/, data_lines[0])
    assert_match(/,2000-01-01 01:00:00,/, data_lines[1])
    assert_match(/,2014-06-10 00:00:00,/, data_lines[2])
  end

  it "returns nil for empty CSV" do
    raw_csv = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
    CSV

    processor = Eodhd::Commands::Process::Subcommands::Intraday::Processor.new(log: Logging::NullLogger.new)
    result_csv = processor.process_csv(raw_csv, [], [])

    assert_nil result_csv
  end

  it "processes CSV without splits or dividends" do
    raw_csv = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      946684800,0,2000-01-01 00:00:00,100.5,101.0,100.0,100.75,1000
      946688400,0,2000-01-01 01:00:00,100.75,102.0,100.5,101.5,1500
    CSV

    processor = Eodhd::Commands::Process::Subcommands::Intraday::Processor.new(log: Logging::NullLogger.new)
    result_csv = processor.process_csv(raw_csv, [], [])

    refute_nil result_csv
    lines = result_csv.split("\n")
    
    assert_equal 3, lines.size
    assert_equal "Timestamp,Datetime,Open,High,Low,Close,Volume", lines[0]
    
    # Verify first data row
    assert_match(/^946684800,2000-01-01 00:00:00,100\.5,101\.0,100\.0,100\.75,1000$/, lines[1])
  end

  it "formats prices with correct decimal places" do
    raw_csv = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      946684800,0,2000-01-01 00:00:00,100.123456,101.987654,100.111111,100.555555,1000
    CSV

    processor = Eodhd::Commands::Process::Subcommands::Intraday::Processor.new(log: Logging::NullLogger.new)
    result_csv = processor.process_csv(raw_csv, [], [])

    refute_nil result_csv
    lines = result_csv.split("\n")
    
    # Prices should be rounded to OUTPUT_DECIMALS (typically 6 decimal places)
    data_line = lines[1]
    parts = data_line.split(",")
    
    # Check that prices are formatted (they should have decimals but be rounded)
    assert_match(/^\d+\.\d+$/, parts[2]) # open
    assert_match(/^\d+\.\d+$/, parts[3]) # high
    assert_match(/^\d+\.\d+$/, parts[4]) # low
    assert_match(/^\d+\.\d+$/, parts[5]) # close
  end

  it "handles splits only" do
    raw_csv = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      946684800,0,2000-01-01 00:00:00,56,56,56,56,10
      946688400,0,2000-01-01 01:00:00,112,112,112,112,20
    CSV

    splits = [
      OpenStruct.new(date: Date.new(2000, 6, 21), factor: 2.0)
    ]

    processor = Eodhd::Commands::Process::Subcommands::Intraday::Processor.new(log: Logging::NullLogger.new)
    result_csv = processor.process_csv(raw_csv, splits, [])

    refute_nil result_csv
    lines = result_csv.split("\n")
    assert_equal 3, lines.size
  end

  it "handles dividends only" do
    raw_csv = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      1402358400,0,2014-06-10 00:00:00,20,20,20,20,60
      1402362000,0,2014-06-10 01:00:00,21,21,21,21,70
    CSV

    dividends = [
      OpenStruct.new(date: Date.new(2014, 6, 11), unadjusted_value: 0.5)
    ]

    processor = Eodhd::Commands::Process::Subcommands::Intraday::Processor.new(log: Logging::NullLogger.new)
    result_csv = processor.process_csv(raw_csv, [], dividends)

    refute_nil result_csv
    lines = result_csv.split("\n")
    assert_equal 3, lines.size
  end
end
