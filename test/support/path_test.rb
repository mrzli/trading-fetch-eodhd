# frozen_string_literal: true

require_relative "../test_helper"

describe Eodhd::Path do
  test_equals(
    ".exchange_symbol_list",
    [
      {
        description: "upper-case code",
        input: "US",
        expected: File.join("symbols", "us.json")
      },
      {
        description: "snake-like code",
        input: "XETRA_GERMANY",
        expected: File.join("symbols", "xetra-germany.json")
      },
      {
        description: "camelCase code",
        input: "FooBar",
        expected: File.join("symbols", "foo-bar.json")
      }
    ],
    call: ->(input) { Eodhd::Path.exchange_symbol_list(exchange_code: input) }
  )
end
