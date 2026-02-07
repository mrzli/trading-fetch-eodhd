# frozen_string_literal: true

require_relative "../test_helper"


describe Util::Validate do
  test_equals(
    ".required_string",
    [
      {
        input: { name: "x", value: "  abc  " },
        expected: "abc"
      }
    ],
    call: ->(input) { Util::Validate.required_string(input[:name], input[:value]) }
  )

  test_raises(
    ".required_string errors",
    [
      {
        input: { name: "x", value: nil },
        exception: ArgumentError
      },
      {
        input: { name: "x", value: "   " },
        exception: ArgumentError
      }
    ],
    call: ->(input) { Util::Validate.required_string(input[:name], input[:value]) }
  )

  test_equals(
    ".http_url",
    [
      {
        input: { name: "base", value: "https://example.com/" },
        expected: "https://example.com"
      },
      {
        input: { name: "base", value: "http://example.com/api" },
        expected: "http://example.com/api"
      }
    ],
    call: ->(input) { Util::Validate.http_url(input[:name], input[:value]) }
  )

  test_raises(
    ".http_url errors",
    [
      {
        description: "ftp:// is rejected",
        input: { name: "base", value: "ftp://example.com" },
        exception: ArgumentError,
      },
      {
        input: { name: "base", value: "" },
        exception: ArgumentError
      }
    ],
    call: ->(input) { Util::Validate.http_url(input[:name], input[:value]) }
  )

  describe "http_url error message" do
    it "includes scheme hint" do
      err = assert_raises(ArgumentError) do
        Util::Validate.http_url("base", "ftp://example.com")
      end
      assert_match(/must start with http:\/\/ or https:\/\//, err.message)
    end
  end

  test_equals(
    ".integer",
    [
      {
        description: "parses positive integer",
        input: { name: "n", value: "123" },
        expected: 123
      },
      {
        description: "parses negative integer",
        input: { name: "n", value: "-5" },
        expected: -5
      },
      {
        description: "strips whitespace",
        input: { name: "n", value: "  7  " },
        expected: 7
      }
    ],
    call: ->(input) { Util::Validate.integer(input[:name], input[:value]) }
  )

  test_raises(
    ".integer errors",
    [
      {
        description: "rejects blank",
        input: { name: "n", value: "  " },
        exception: ArgumentError
      },
      {
        description: "rejects non-integer",
        input: { name: "n", value: "12.3" },
        exception: ArgumentError
      },
      {
        description: "rejects junk",
        input: { name: "n", value: "abc" },
        exception: ArgumentError
      }
    ],
    call: ->(input) { Util::Validate.integer(input[:name], input[:value]) }  )

  test_equals(
    ".integer_non_negative",
    [
      {
        description: "accepts zero",
        input: { name: "n", value: "0" },
        expected: 0
      },
      {
        description: "accepts positive",
        input: { name: "n", value: "42" },
        expected: 42
      }
    ],
    call: ->(input) { Util::Validate.integer_non_negative(input[:name], input[:value]) }
  )

  test_raises(
    ".integer_non_negative errors",
    [
      {
        description: "rejects negative",
        input: { name: "n", value: "-1" },
        exception: ArgumentError
      },
      {
        description: "rejects non-integer",
        input: { name: "n", value: "1.5" },
        exception: ArgumentError
      },
      {
        description: "rejects blank",
        input: { name: "n", value: "  " },
        exception: ArgumentError
      }
    ],
    call: ->(input) { Util::Validate.integer_non_negative(input[:name], input[:value]) }
  )

  test_equals(
    ".integer_positive",
    [
      {
        description: "accepts positive",
        input: { name: "n", value: "1" },
        expected: 1
      },
      {
        description: "accepts large positive",
        input: { name: "n", value: "42" },
        expected: 42
      }
    ],
    call: ->(input) { Util::Validate.integer_positive(input[:name], input[:value]) }
  )

  test_raises(
    ".integer_positive errors",
    [
      {
        description: "rejects zero",
        input: { name: "n", value: "0" },
        exception: ArgumentError
      },
      {
        description: "rejects negative",
        input: { name: "n", value: "-1" },
        exception: ArgumentError
      },
      {
        description: "rejects non-integer",
        input: { name: "n", value: "1.5" },
        exception: ArgumentError
      },
      {
        description: "rejects blank",
        input: { name: "n", value: "  " },
        exception: ArgumentError
      }
    ],
    call: ->(input) { Util::Validate.integer_positive(input[:name], input[:value]) }
  )
end