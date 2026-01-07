# frozen_string_literal: true

require_relative "../../test_helper"

describe Eodhd::IntradayProcessor do
  it "merges overlaps, splits by year, and split-adjusts prices" do
    csv1 = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      1070283720,0,"2003-12-01 13:02:00",20.99,20.99,20.99,20.99,200
      1070283780,0,"2003-12-01 13:03:00",21.1,21.1,21.1,21.1,100
    CSV

    # Overlaps timestamp 1070283780 (later file should win) and adds another row.
    csv2 = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      1070283780,0,"2003-12-01 13:03:00",21.2,21.2,21.2,21.2,150
      1070285040,0,"2003-12-01 13:24:00",21.11,21.11,21.11,21.11,400
      1070323140,0,"2003-12-01 23:59:00",40,40,40,40,10
      1070352000,0,"2003-12-02 08:00:00",50,50,50,50,10
      1073058000,0,"2004-01-02 13:00:00",10,10,10,10,1
    CSV

    splits_json = <<~JSON
      [
        {"date":"2003-12-02","split":"2.000000/1.000000"},
        {"date":"2004-01-01","split":"2.000000/1.000000"}
      ]
    JSON

    splits = Eodhd::SplitsParser.parse_splits!(splits_json)
    out = Eodhd::IntradayProcessor.process_csv_files!([csv1, csv2], splits)

    expected_2003 = <<~CSV
      Timestamp,Datetime,Open,High,Low,Close,Volume
      1070283720,2003-12-01 13:02:00,5.2475,5.2475,5.2475,5.2475,800
      1070283780,2003-12-01 13:03:00,5.3,5.3,5.3,5.3,600
      1070285040,2003-12-01 13:24:00,5.2775,5.2775,5.2775,5.2775,1600
      1070323140,2003-12-01 23:59:00,10.0,10.0,10.0,10.0,40
      1070352000,2003-12-02 08:00:00,25.0,25.0,25.0,25.0,20
    CSV

    expected_2004 = <<~CSV
      Timestamp,Datetime,Open,High,Low,Close,Volume
      1073058000,2004-01-02 13:00:00,10.0,10.0,10.0,10.0,1
    CSV

    assert_equal expected_2003, out.fetch(2003)
    assert_equal expected_2004, out.fetch(2004)
  end

  it "raises when Gmtoffset is non-zero (no splits)" do
    raw = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      1070236800,3600,"2003-12-01 01:00:00",1,2,0.5,1.5,10
    CSV

    err = _(-> { Eodhd::IntradayProcessor.process_csv_files!([raw], []) }).must_raise(Eodhd::IntradayProcessor::Error)
    _(err.message).must_match(/Gmtoffset=0/i)
  end

  it "crops old rows when a later file overlaps" do
    csv1 = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      100,0,"2003-12-01 00:00:00",1,1,1,1,10
      200,0,"2003-12-01 00:01:00",2,2,2,2,20
      300,0,"2003-12-01 00:02:00",3,3,3,3,30
    CSV

    # Starts at 200, so 200+ rows from csv1 should be discarded.
    csv2 = <<~CSV
      Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
      200,0,"2003-12-01 00:01:00",22,22,22,22,220
      250,0,"2003-12-01 00:01:30",25,25,25,25,250
    CSV

    out = Eodhd::IntradayProcessor.process_csv_files!([csv1, csv2], [])

    expected = <<~CSV
      Timestamp,Datetime,Open,High,Low,Close,Volume
      100,2003-12-01 00:00:00,1.0,1.0,1.0,1.0,10
      200,2003-12-01 00:01:00,22.0,22.0,22.0,22.0,220
      250,2003-12-01 00:01:30,25.0,25.0,25.0,25.0,250
    CSV

    assert_equal expected, out.fetch(2003)
  end
end
