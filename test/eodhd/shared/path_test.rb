# frozen_string_literal: true

require_relative "../../test_helper"

describe Eodhd::Shared::Path do
  test_equals(
    ".exchanges_file",
    [
      {
        input: nil,
        expected: "exchanges.json"
      }
    ],
    call: ->(_input) { Eodhd::Shared::Path.exchanges_file }
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
    call: ->(input) { Eodhd::Shared::Path.exchange_symbol_list(input[:exchange_code], input[:type]) }
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
    call: ->(input) { Eodhd::Shared::Path.splits(input[:exchange], input[:symbol]) }
  )

  test_equals(
    ".dividends",
    [
      {
        description: "symbol with exchange",
        input: { exchange: "US", symbol: "AAPL" },
        expected: File.join("meta", "us", "aapl", "dividends.json")
      },
      {
        description: "symbol with dot class",
        input: { exchange: "US", symbol: "BRK.B" },
        expected: File.join("meta", "us", "brk-b", "dividends.json")
      }
    ],
    call: ->(input) { Eodhd::Shared::Path.dividends(input[:exchange], input[:symbol]) }
  )

  test_equals(
    ".raw_eod_dir",
    [
      {
        description: "hardcoded root",
        input: nil,
        expected: File.join("raw", "eod")
      }
    ],
    call: ->(_input) { Eodhd::Shared::Path.raw_eod_dir }
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
    call: ->(input) { Eodhd::Shared::Path.raw_eod_data(input[:exchange], input[:symbol]) }
  )

  test_equals(
    ".raw_intraday_dir",
    [
      {
        description: "hardcoded root",
        input: nil,
        expected: File.join("raw", "intraday")
      }
    ],
    call: ->(_input) { Eodhd::Shared::Path.raw_intraday_dir }
  )

  test_equals(
    ".raw_intraday_fetched_dir",
    [
      {
        description: "hardcoded fetched root",
        input: nil,
        expected: File.join("raw", "intraday", "fetched")
      }
    ],
    call: ->(_input) { Eodhd::Shared::Path.raw_intraday_fetched_dir }
  )

  test_equals(
    ".raw_intraday_fetched_symbol_data_dir",
    [
      {
        description: "symbol with exchange",
        input: { exchange: "US", symbol: "AAPL" },
        expected: File.join("raw", "intraday", "fetched", "us", "aapl")
      },
      {
        description: "symbol with dot class",
        input: { exchange: "US", symbol: "BRK.B" },
        expected: File.join("raw", "intraday", "fetched", "us", "brk-b")
      }
    ],
    call: ->(input) { Eodhd::Shared::Path.raw_intraday_fetched_symbol_data_dir(input[:exchange], input[:symbol]) }
  )

  test_equals(
    ".raw_intraday_fetched_symbol_data",
    [
      {
        description: "symbol with exchange",
        input: { exchange: "US", symbol: "AAPL", from: 0, to: 100 },
        expected: File.join("raw", "intraday", "fetched", "us", "aapl", "1970-01-01_00-00-00__1970-01-01_00-01-40.csv")
      },
      {
        description: "symbol with dot class",
        input: { exchange: "US", symbol: "BRK.B", from: 123, to: 456 },
        expected: File.join("raw", "intraday", "fetched", "us", "brk-b", "1970-01-01_00-02-03__1970-01-01_00-07-36.csv")
      }
    ],
    call: ->(input) { Eodhd::Shared::Path.raw_intraday_fetched_symbol_data(input[:exchange], input[:symbol], input[:from], input[:to]) }
  )

  test_equals(
    ".raw_intraday_processed_dir",
    [
      {
        description: "hardcoded processed root",
        input: nil,
        expected: File.join("raw", "intraday", "processed")
      }
    ],
    call: ->(_input) { Eodhd::Shared::Path.raw_intraday_processed_dir }
  )

  test_equals(
    ".raw_intraday_processed_symbol_data_dir",
    [
      {
        description: "symbol with exchange",
        input: { exchange: "US", symbol: "AAPL" },
        expected: File.join("raw", "intraday", "processed", "us", "aapl")
      },
      {
        description: "symbol with dot class",
        input: { exchange: "US", symbol: "BRK.B" },
        expected: File.join("raw", "intraday", "processed", "us", "brk-b")
      }
    ],
    call: ->(input) { Eodhd::Shared::Path.raw_intraday_processed_symbol_data_dir(input[:exchange], input[:symbol]) }
  )

  test_equals(
    ".raw_intraday_processed_symbol_year_month",
    [
      {
        description: "year and month file",
        input: { exchange: "US", symbol: "AAPL", year: 2025, month: 6 },
        expected: File.join("raw", "intraday", "processed", "us", "aapl", "2025-06.csv")
      },
      {
        description: "symbol with dot class",
        input: { exchange: "US", symbol: "BRK.B", year: 2024, month: 12 },
        expected: File.join("raw", "intraday", "processed", "us", "brk-b", "2024-12.csv")
      }
    ],
    call: ->(input) { Eodhd::Shared::Path.raw_intraday_processed_symbol_year_month(input[:exchange], input[:symbol], input[:year], input[:month]) }
  )

  test_equals(
    ".processed_eod_data",
    [
      {
        description: "symbol with exchange",
        input: { exchange: "US", symbol: "MCD" },
        expected: File.join("data", "eod", "us", "mcd.csv")
      },
      {
        description: "symbol with dot class",
        input: { exchange: "US", symbol: "BRK.B" },
        expected: File.join("data", "eod", "us", "brk-b.csv")
      }
    ],
    call: ->(input) { Eodhd::Shared::Path.processed_eod_data(input[:exchange], input[:symbol]) }
  )

  test_equals(
    ".processed_intraday_data_dir",
    [
      {
        description: "symbol with exchange",
        input: { exchange: "US", symbol: "AAPL" },
        expected: File.join("data", "intraday", "us", "aapl")
      },
      {
        description: "symbol with dot class",
        input: { exchange: "US", symbol: "BRK.B" },
        expected: File.join("data", "intraday", "us", "brk-b")
      }
    ],
    call: ->(input) { Eodhd::Shared::Path.processed_intraday_data_dir(input[:exchange], input[:symbol]) }
  )

  test_equals(
    ".processed_intraday_year_month",
    [
      {
        description: "year file",
        input: { exchange: "US", symbol: "AAPL", year: 2003, month: 1 },
        expected: File.join("data", "intraday", "us", "aapl", "2003-01.csv")
      }
    ],
    call: ->(input) { Eodhd::Shared::Path.processed_intraday_year_month(input[:exchange], input[:symbol], input[:year], input[:month]) }
  )
end
