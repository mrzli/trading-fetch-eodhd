# frozen_string_literal: true

require_relative "../../../../../test_helper"
require_relative "../../../../../../lib/eodhd/commands/fetch/components/intraday/intraday_csv_grouper"

# Helper methods at module level
def row(timestamp)
  time = Time.at(timestamp).utc
  {
    timestamp: timestamp,
    gmtoffset: 0,
    datetime: time.strftime("%Y-%m-%d %H:%M:%S"),
    open: 100,
    high: 101,
    low: 99,
    close: 100,
    volume: 1000
  }
end

def rows(*timestamps)
  timestamps.map { |ts| row(ts) }
end

def ts(year, month, day, hour = 0, minute = 0, second = 0)
  Time.new(year, month, day, hour, minute, second, "+00:00").to_i
end

describe Eodhd::IntradayCsvGrouper do
  test_equals(
    ".group_by_month",
    [
      {
        description: "returns empty hash when rows is nil",
        input: nil,
        expected: {}
      },
      {
        description: "returns empty hash when rows is empty",
        input: [],
        expected: {}
      },
      {
        description: "groups single month",
        input: rows(
          ts(2025, 1, 15, 10, 0),
          ts(2025, 1, 15, 11, 0),
          ts(2025, 1, 15, 12, 0)
        ),
        expected: {
          [2025, 1] => rows(
            ts(2025, 1, 15, 10, 0),
            ts(2025, 1, 15, 11, 0),
            ts(2025, 1, 15, 12, 0)
          )
        }
      },
      {
        description: "groups two consecutive months",
        input: rows(
          ts(2025, 1, 31, 23, 0),
          ts(2025, 2, 1, 0, 0),
          ts(2025, 2, 1, 1, 0)
        ),
        expected: {
          [2025, 1] => rows(ts(2025, 1, 31, 23, 0)),
          [2025, 2] => rows(ts(2025, 2, 1, 0, 0), ts(2025, 2, 1, 1, 0))
        }
      },
      {
        description: "groups spanning year boundary",
        input: rows(
          ts(2024, 12, 31, 23, 0),
          ts(2025, 1, 1, 0, 0),
          ts(2025, 1, 1, 1, 0)
        ),
        expected: {
          [2024, 12] => rows(ts(2024, 12, 31, 23, 0)),
          [2025, 1] => rows(ts(2025, 1, 1, 0, 0), ts(2025, 1, 1, 1, 0))
        }
      },
      {
        description: "groups with gap - skips empty months",
        input: rows(
          ts(2025, 1, 15, 10, 0),
          ts(2025, 3, 15, 10, 0)
        ),
        expected: {
          [2025, 1] => rows(ts(2025, 1, 15, 10, 0)),
          [2025, 3] => rows(ts(2025, 3, 15, 10, 0))
        }
      },
      {
        description: "groups multiple months with varying data",
        input: rows(
          ts(2025, 1, 1, 0, 0),
          ts(2025, 1, 31, 23, 59),
          ts(2025, 2, 1, 0, 0),
          ts(2025, 2, 15, 12, 0),
          ts(2025, 2, 28, 23, 59),
          ts(2025, 3, 1, 0, 0)
        ),
        expected: {
          [2025, 1] => rows(ts(2025, 1, 1, 0, 0), ts(2025, 1, 31, 23, 59)),
          [2025, 2] => rows(ts(2025, 2, 1, 0, 0), ts(2025, 2, 15, 12, 0), ts(2025, 2, 28, 23, 59)),
          [2025, 3] => rows(ts(2025, 3, 1, 0, 0))
        }
      },
      {
        description: "handles leap year February",
        input: rows(
          ts(2024, 2, 28, 23, 0),
          ts(2024, 2, 29, 12, 0),
          ts(2024, 3, 1, 0, 0)
        ),
        expected: {
          [2024, 2] => rows(ts(2024, 2, 28, 23, 0), ts(2024, 2, 29, 12, 0)),
          [2024, 3] => rows(ts(2024, 3, 1, 0, 0))
        }
      },
      {
        description: "groups entire year",
        input: rows(
          ts(2025, 1, 1, 0, 0),
          ts(2025, 6, 15, 12, 0),
          ts(2025, 12, 31, 23, 59)
        ),
        expected: {
          [2025, 1] => rows(ts(2025, 1, 1, 0, 0)),
          [2025, 6] => rows(ts(2025, 6, 15, 12, 0)),
          [2025, 12] => rows(ts(2025, 12, 31, 23, 59))
        }
      },
      {
        description: "groups single row",
        input: rows(ts(2025, 5, 15, 10, 30)),
        expected: {
          [2025, 5] => rows(ts(2025, 5, 15, 10, 30))
        }
      },
      {
        description: "groups at month boundaries",
        input: rows(
          ts(2025, 1, 31, 23, 59, 59),
          ts(2025, 2, 1, 0, 0, 0),
          ts(2025, 2, 28, 23, 59, 59),
          ts(2025, 3, 1, 0, 0, 0)
        ),
        expected: {
          [2025, 1] => rows(ts(2025, 1, 31, 23, 59, 59)),
          [2025, 2] => rows(ts(2025, 2, 1, 0, 0, 0), ts(2025, 2, 28, 23, 59, 59)),
          [2025, 3] => rows(ts(2025, 3, 1, 0, 0, 0))
        }
      }
    ],
    call: ->(input) { Eodhd::IntradayCsvGrouper.group_by_month(input) }
  )
end
