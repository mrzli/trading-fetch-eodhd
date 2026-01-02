# frozen_string_literal: true

require_relative "../test_helper"

describe Eodhd::Path do
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
    ".eod_data",
    [
      {
        description: "symbol with exchange",
        input: { exchange: "US", symbol: "MCD" },
        expected: File.join("eod", "mcd.us.json")
      },
      {
        description: "symbol with dot class",
        input: { exchange: "US", symbol: "BRK.B" },
        expected: File.join("eod", "brk-b.us.json")
      }
    ],
    call: ->(input) { Eodhd::Path.eod_data(input[:exchange], input[:symbol]) }
  )
end
