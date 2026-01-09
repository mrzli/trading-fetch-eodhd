# frozen_string_literal: true

require_relative "../../../test_helper"

require "bigdecimal"
require_relative "../../../../lib/eodhd/process/intraday/data_splitter"

describe Eodhd::DataSplitter do
  describe "YearMonth" do
    it "formats as YYYY-MM" do
      ym = Eodhd::DataSplitter::YearMonth.new(2020, 1)
      assert_equal "2020-01", ym.to_s

      ym2 = Eodhd::DataSplitter::YearMonth.new(2020, 12)
      assert_equal "2020-12", ym2.to_s
    end
  end

  describe ".by_month" do
    it "returns empty array for nil data" do
      result = Eodhd::DataSplitter.by_month(nil)
      assert_equal [], result
    end

    it "returns empty array for empty data" do
      result = Eodhd::DataSplitter.by_month([])
      assert_equal [], result
    end

    it "groups data by year-month" do
      data = [
        { timestamp: 100, datetime: "2020-01-15 10:00:00", open: BigDecimal("1"), high: BigDecimal("2"), low: BigDecimal("1"), close: BigDecimal("1.5"), volume: 10 },
        { timestamp: 200, datetime: "2020-01-20 11:00:00", open: BigDecimal("2"), high: BigDecimal("3"), low: BigDecimal("2"), close: BigDecimal("2.5"), volume: 20 },
        { timestamp: 300, datetime: "2020-02-05 12:00:00", open: BigDecimal("3"), high: BigDecimal("4"), low: BigDecimal("3"), close: BigDecimal("3.5"), volume: 30 },
        { timestamp: 400, datetime: "2021-01-10 13:00:00", open: BigDecimal("4"), high: BigDecimal("5"), low: BigDecimal("4"), close: BigDecimal("4.5"), volume: 40 }
      ]

      result = Eodhd::DataSplitter.by_month(data)

      expected = [
        [
          Eodhd::DataSplitter::YearMonth.new(2020, 1),
          [
            { timestamp: 100, datetime: "2020-01-15 10:00:00", open: BigDecimal("1"), high: BigDecimal("2"), low: BigDecimal("1"), close: BigDecimal("1.5"), volume: 10 },
            { timestamp: 200, datetime: "2020-01-20 11:00:00", open: BigDecimal("2"), high: BigDecimal("3"), low: BigDecimal("2"), close: BigDecimal("2.5"), volume: 20 }
          ]
        ],
        [
          Eodhd::DataSplitter::YearMonth.new(2020, 2),
          [
            { timestamp: 300, datetime: "2020-02-05 12:00:00", open: BigDecimal("3"), high: BigDecimal("4"), low: BigDecimal("3"), close: BigDecimal("3.5"), volume: 30 }
          ]
        ],
        [
          Eodhd::DataSplitter::YearMonth.new(2021, 1),
          [
            { timestamp: 400, datetime: "2021-01-10 13:00:00", open: BigDecimal("4"), high: BigDecimal("5"), low: BigDecimal("4"), close: BigDecimal("4.5"), volume: 40 }
          ]
        ]
      ]

      assert_equal expected, result
    end

    it "sorts output by year and month" do
      data = [
        { timestamp: 400, datetime: "2021-01-10 13:00:00", open: BigDecimal("4"), high: BigDecimal("4"), low: BigDecimal("4"), close: BigDecimal("4"), volume: 40 },
        { timestamp: 100, datetime: "2020-01-15 10:00:00", open: BigDecimal("1"), high: BigDecimal("1"), low: BigDecimal("1"), close: BigDecimal("1"), volume: 10 },
        { timestamp: 300, datetime: "2020-02-05 12:00:00", open: BigDecimal("3"), high: BigDecimal("3"), low: BigDecimal("3"), close: BigDecimal("3"), volume: 30 }
      ]

      result = Eodhd::DataSplitter.by_month(data)

      expected = [
        [
          Eodhd::DataSplitter::YearMonth.new(2020, 1),
          [
            { timestamp: 100, datetime: "2020-01-15 10:00:00", open: BigDecimal("1"), high: BigDecimal("1"), low: BigDecimal("1"), close: BigDecimal("1"), volume: 10 }
          ]
        ],
        [
          Eodhd::DataSplitter::YearMonth.new(2020, 2),
          [
            { timestamp: 300, datetime: "2020-02-05 12:00:00", open: BigDecimal("3"), high: BigDecimal("3"), low: BigDecimal("3"), close: BigDecimal("3"), volume: 30 }
          ]
        ],
        [
          Eodhd::DataSplitter::YearMonth.new(2021, 1),
          [
            { timestamp: 400, datetime: "2021-01-10 13:00:00", open: BigDecimal("4"), high: BigDecimal("4"), low: BigDecimal("4"), close: BigDecimal("4"), volume: 40 }
          ]
        ]
      ]

      assert_equal expected, result
    end
  end
end
