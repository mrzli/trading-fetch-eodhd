# frozen_string_literal: true

require_relative "../../test_helper"

describe Eodhd::Path do
  test_equals(
    ".exchanges_list",
    [
      {
        description: "filename",
        input: nil,
        expected: "exchanges-list.json"
      }
    ],
    call: ->(_input) { Eodhd::Path.exchanges_list }
  )

  test_equals(
    ".exchange_symbol_list",
    [
      {
        description: "upper-case code and type",
        input: { exchange_code: "US", type: "Common Stock" },
        expected: File.join("symbols", "us", "common-stock.json")
      },
      {
        description: "snake-like code and type",
        input: { exchange_code: "XETRA_GERMANY", type: "ETF" },
        expected: File.join("symbols", "xetra-germany", "etf.json")
      },
      {
        description: "camelCase code and type",
        input: { exchange_code: "FooBar", type: "MutualFund" },
        expected: File.join("symbols", "foo-bar", "mutual-fund.json")
      }
    ],
    call: ->(input) { Eodhd::Path.exchange_symbol_list(input[:exchange_code], input[:type]) }
  )

  test_equals(
    ".raw_eod_data",
    [
      {
        description: "symbol with exchange",
        input: { exchange: "US", symbol: "MCD" },
        expected: File.join("raw", "eod", "us", "mcd.csv")
      },
      {
        description: "symbol with dot class",
        input: { exchange: "US", symbol: "BRK.B" },
        expected: File.join("raw", "eod", "us", "brk-b.csv")
      }
    ],
    call: ->(input) { Eodhd::Path.raw_eod_data(input[:exchange], input[:symbol]) }
  )

  test_equals(
    ".raw_intraday_data_dir",
    [
      {
        description: "symbol with exchange",
        input: { exchange: "US", symbol: "AAPL" },
        expected: File.join("raw", "intraday", "us", "aapl")
      },
      {
        description: "symbol with dot class",
        input: { exchange: "US", symbol: "BRK.B" },
        expected: File.join("raw", "intraday", "us", "brk-b")
      }
    ],
    call: ->(input) { Eodhd::Path.raw_intraday_data_dir(input[:exchange], input[:symbol]) }
  )

  test_equals(
    ".raw_intraday_data_dir",
    [
      {
        description: "symbol with exchange",
        input: { exchange: "US", symbol: "AAPL" },
        expected: File.join("raw", "intraday", "us", "aapl")
      },
      {
        description: "symbol with dot class",
        input: { exchange: "US", symbol: "BRK.B" },
        expected: File.join("raw", "intraday", "us", "brk-b")
      }
    ],
    call: ->(input) { Eodhd::Path.raw_intraday_data_dir(input[:exchange], input[:symbol]) }
  )

  test_equals(
    ".raw_intraday_data",
    [
      {
        description: "symbol with exchange",
        input: { exchange: "US", symbol: "AAPL", from: 0 },
        expected: File.join("raw", "intraday", "us", "aapl", "1970-01-01_00-00-00.csv")
      },
      {
        description: "symbol with dot class",
        input: { exchange: "US", symbol: "BRK.B", from: 123 },
        expected: File.join("raw", "intraday", "us", "brk-b", "1970-01-01_00-02-03.csv")
      }
    ],
    call: ->(input) { Eodhd::Path.raw_intraday_data(input[:exchange], input[:symbol], input[:from]) }
  )

  test_equals(
    ".splits",
    [
      {
        description: "symbol with exchange",
        input: { exchange: "US", symbol: "AAPL" },
        expected: File.join("meta", "us", "aapl", "splits.json")
      },
      {
        description: "symbol with dot class",
        input: { exchange: "US", symbol: "BRK.B" },
        expected: File.join("meta", "us", "brk-b", "splits.json")
      }
    ],
    call: ->(input) { Eodhd::Path.splits(input[:exchange], input[:symbol]) }
  )
end
