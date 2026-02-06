# frozen_string_literal: true

require_relative "../test_helper"

require_relative "../../lib/util"

describe Util::Date do
  test_equals(
    ".seconds_to_datetime",
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
    call: ->(input) { Util::Date.seconds_to_datetime(input) }
  )

  test_raises(
    ".seconds_to_datetime errors",
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
    call: ->(input) { Util::Date.seconds_to_datetime(input) }
  )

  test_equals(
    ".datetime_to_seconds",
    [
      {
        description: "epoch 0",
        input: "1970-01-01_00-00-00",
        expected: 0
      },
      {
        description: "integer seconds",
        input: "1970-01-01_00-02-03",
        expected: 123
      },
      {
        description: "whitespace is stripped",
        input: "  1970-01-01_00-00-07  ",
        expected: 7
      },
      {
        description: "round trip (no timezone ambiguity)",
        input: Util::Date.seconds_to_datetime(1_700_000_000),
        expected: 1_700_000_000
      }
    ],
    call: ->(input) { Util::Date.datetime_to_seconds(input) }
  )

  test_raises(
    ".datetime_to_seconds errors",
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
      },
      {
        description: "wrong separators rejected",
        input: "1970/01/01 00:00:00",
        exception: ArgumentError
      }
    ],
    call: ->(input) { Util::Date.datetime_to_seconds(input) }
  )
end
