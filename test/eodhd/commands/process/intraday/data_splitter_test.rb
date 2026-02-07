# frozen_string_literal: true

require_relative "../../../../test_helper"

require_relative "../../../../../lib/eodhd/commands/process/intraday/data_splitter"

describe Eodhd::Commands::Process::Intraday::DataSplitter do
  describe "YearMonth" do
    it "formats as YYYY-MM" do
      ym = Eodhd::Commands::Process::Intraday::DataSplitter::YearMonth.new(2020, 1)
      assert_equal "2020-01", ym.to_s

      ym2 = Eodhd::Commands::Process::Intraday::DataSplitter::YearMonth.new(2020, 12)
      assert_equal "2020-12", ym2.to_s
    end
  end

  describe ".by_month" do
    it "returns empty array for nil data" do
      result = Eodhd::Commands::Process::Intraday::DataSplitter.by_month(nil)
      assert_equal [], result
    end

    it "returns empty array for empty data" do
      result = Eodhd::Commands::Process::Intraday::DataSplitter.by_month([])
      assert_equal [], result
    end

    it "groups data by year-month" do
      data = [
        { timestamp: 100, datetime: "2020-01-15 10:00:00", open: 1.0, high: 2.0, low: 1.0, close: 1.5, volume: 10 },
        { timestamp: 200, datetime: "2020-01-20 11:00:00", open: 2.0, high: 3.0, low: 2.0, close: 2.5, volume: 20 },
        { timestamp: 300, datetime: "2020-02-05 12:00:00", open: 3.0, high: 4.0, low: 3.0, close: 3.5, volume: 30 },
        { timestamp: 400, datetime: "2021-01-10 13:00:00", open: 4.0, high: 5.0, low: 4.0, close: 4.5, volume: 40 }
      ]

      result = Eodhd::Commands::Process::Intraday::DataSplitter.by_month(data)

      expected = [
        {
          key: Eodhd::Commands::Process::Intraday::DataSplitter::YearMonth.new(2020, 1),
          value: [
            { timestamp: 100, datetime: "2020-01-15 10:00:00", open: 1.0, high: 2.0, low: 1.0, close: 1.5, volume: 10 },
            { timestamp: 200, datetime: "2020-01-20 11:00:00", open: 2.0, high: 3.0, low: 2.0, close: 2.5, volume: 20 }
          ]
        },
        {
          key: Eodhd::Commands::Process::Intraday::DataSplitter::YearMonth.new(2020, 2),
          value: [
            { timestamp: 300, datetime: "2020-02-05 12:00:00", open: 3.0, high: 4.0, low: 3.0, close: 3.5, volume: 30 }
          ]
        },
        {
          key: Eodhd::Commands::Process::Intraday::DataSplitter::YearMonth.new(2021, 1),
          value: [
            { timestamp: 400, datetime: "2021-01-10 13:00:00", open: 4.0, high: 5.0, low: 4.0, close: 4.5, volume: 40 }
          ]
        }
      ]

      assert_equal expected, result
    end

    it "sorts output by year and month" do
      data = [
        { timestamp: 400, datetime: "2021-01-10 13:00:00", open: 4.0, high: 4.0, low: 4.0, close: 4.0, volume: 40 },
        { timestamp: 100, datetime: "2020-01-15 10:00:00", open: 1.0, high: 1.0, low: 1.0, close: 1.0, volume: 10 },
        { timestamp: 300, datetime: "2020-02-05 12:00:00", open: 3.0, high: 3.0, low: 3.0, close: 3.0, volume: 30 }
      ]

      result = Eodhd::Commands::Process::Intraday::DataSplitter.by_month(data)

      expected = [
        {
          key: Eodhd::Commands::Process::Intraday::DataSplitter::YearMonth.new(2020, 1),
          value: [
            { timestamp: 100, datetime: "2020-01-15 10:00:00", open: 1.0, high: 1.0, low: 1.0, close: 1.0, volume: 10 }
          ]
        },
        {
          key: Eodhd::Commands::Process::Intraday::DataSplitter::YearMonth.new(2020, 2),
          value: [
            { timestamp: 300, datetime: "2020-02-05 12:00:00", open: 3.0, high: 3.0, low: 3.0, close: 3.0, volume: 30 }
          ]
        },
        {
          key: Eodhd::Commands::Process::Intraday::DataSplitter::YearMonth.new(2021, 1),
          value: [
            { timestamp: 400, datetime: "2021-01-10 13:00:00", open: 4.0, high: 4.0, low: 4.0, close: 4.0, volume: 40 }
          ]
        }
      ]

      assert_equal expected, result
    end
  end
end
