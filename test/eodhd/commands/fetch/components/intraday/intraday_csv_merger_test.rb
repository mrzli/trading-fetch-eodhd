# frozen_string_literal: true

require_relative "../../../../../test_helper"
require_relative "../../../../../../lib/eodhd/commands/fetch/components/intraday/intraday_csv_merger"

# Helper methods at module level
def rowe(timestamp)
  { timestamp: timestamp, gmtoffset: 0, datetime: "2025-01-01 00:00:00", open: 100, high: 101, low: 99, close: 100, volume: 1000 }
end

def rown(timestamp)
  { timestamp: timestamp, gmtoffset: 0, datetime: "2025-01-01 00:00:00", open: 200, high: 201, low: 199, close: 200, volume: 2000 }
end

def rowse(*timestamps)
  timestamps.map { |ts| rowe(ts) }
end

def rowsn(*timestamps)
  timestamps.map { |ts| rown(ts) }
end

describe Eodhd::Commands::IntradayCsvMerger do
  test_equals(
    ".merge",
    [
      {
        description: "returns new rows when existing is nil",
        input: {
          existing_csv: nil,
          new_csv: rowsn(100, 200)
        },
        expected: rowsn(100, 200)
      },
      {
        description: "returns new rows when existing is empty",
        input: {
          existing_csv: [],
          new_csv: rowsn(100, 200)
        },
        expected: rowsn(100, 200)
      },
      {
        description: "returns existing rows when new is nil",
        input: {
          existing_csv: rowse(100, 200),
          new_csv: nil
        },
        expected: rowse(100, 200)
      },
      {
        description: "returns existing rows when new is empty",
        input: {
          existing_csv: rowse(100, 200),
          new_csv: []
        },
        expected: rowse(100, 200)
      },
      {
        description: "handles no overlap - new data after existing",
        input: {
          existing_csv: rowse(100, 200, 300),
          new_csv: rowsn(500, 600)
        },
        expected: rowse(100, 200, 300) + rowsn(500, 600)
      },
      {
        description: "handles no overlap - new data before existing",
        input: {
          existing_csv: rowse(500, 600, 700),
          new_csv: rowsn(100, 200)
        },
        expected: rowsn(100, 200) + rowse(500, 600, 700)
      },
      {
        description: "handles new data starting at existing timestamp",
        input: {
          existing_csv: rowse(100, 200, 300, 400),
          new_csv: rowsn(200, 250)
        },
        expected: rowse(100) + rowsn(200, 250) + rowse(300, 400)
      },
      {
        description: "handles new data ending at existing timestamp",
        input: {
          existing_csv: rowse(100, 200, 300, 400),
          new_csv: rowsn(250, 300)
        },
        expected: rowse(100, 200) + rowsn(250, 300) + rowse(400)
      },
      {
        description: "handles partial overlap - new data overlaps end of existing",
        input: {
          existing_csv: rowse(100, 200, 300, 400),
          new_csv: rowsn(250, 350, 450)
        },
        expected: rowse(100, 200) + rowsn(250, 350, 450)
      },
      {
        description: "handles partial overlap - new data overlaps start of existing",
        input: {
          existing_csv: rowse(300, 400, 500, 600),
          new_csv: rowsn(200, 350, 450)
        },
        expected: rowsn(200, 350, 450) + rowse(500, 600)
      },
      {
        description: "handles new data completely within existing (subset)",
        input: {
          existing_csv: rowse(100, 200, 300, 400, 500),
          new_csv: rowsn(250, 350)
        },
        expected: rowse(100, 200) + rowsn(250, 350) + rowse(400, 500)
      },
      {
        description: "handles new data completely containing existing (superset)",
        input: {
          existing_csv: rowse(300, 400),
          new_csv: rowsn(100, 200, 300, 400, 500, 600)
        },
        expected: rowsn(100, 200, 300, 400, 500, 600)
      },
      {
        description: "handles complete replacement - exact same range",
        input: {
          existing_csv: rowse(100, 200, 300),
          new_csv: rowsn(100, 200, 300)
        },
        expected: rowsn(100, 200, 300)
      },
      {
        description: "handles replacing middle section with gap before and after",
        input: {
          existing_csv: rowse(100, 200, 500, 600, 900, 1000),
          new_csv: rowsn(550, 650, 750)
        },
        expected: rowse(100, 200, 500) + rowsn(550, 650, 750) + rowse(900, 1000)
      },
      {
        description: "handles exclude range covering all existing data",
        input: {
          existing_csv: rowse(200, 300, 400),
          new_csv: rowsn(100, 500)
        },
        expected: rowsn(100, 500)
      },
      {
        description: "handles exclude range with no matching existing data",
        input: {
          existing_csv: rowse(100, 200, 700, 800),
          new_csv: rowsn(400, 500)
        },
        expected: rowse(100, 200) + rowsn(400, 500) + rowse(700, 800)
      }
    ],
    call: ->(input) { Eodhd::Commands::IntradayCsvMerger.merge(input[:existing_csv], input[:new_csv]) }
  )
end
