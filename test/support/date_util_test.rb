# frozen_string_literal: true

require_relative "../test_helper"

describe Eodhd::DateUtil do
  test_equals(
    ".utc_compact_datetime",
    [
      {
        description: "epoch 0",
        input: 0,
        expected: "1970-01-01_00-00-00"
      },
      {
        description: "integer seconds",
        input: 123,
        expected: "1970-01-01_00-02-03"
      },
      {
        description: "string seconds",
        input: "123",
        expected: "1970-01-01_00-02-03"
      },
      {
        description: "whitespace is stripped",
        input: "  7  ",
        expected: "1970-01-01_00-00-07"
      }
    ],
    call: ->(input) { Eodhd::DateUtil.utc_compact_datetime(input) }
  )

  test_raises(
    ".utc_compact_datetime errors",
    [
      {
        description: "blank is rejected",
        input: " ",
        exception: ArgumentError
      },
      {
        description: "junk is rejected",
        input: "abc",
        exception: ArgumentError
      }
    ],
    call: ->(input) { Eodhd::DateUtil.utc_compact_datetime(input) }
  )
end
