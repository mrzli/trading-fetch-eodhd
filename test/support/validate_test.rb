# frozen_string_literal: true

require_relative "../test_helper"

describe Eodhd::Validate do
  test_equals(
    ".required_string!",
    [
      {
        input: { name: "x", value: "  abc  " },
        expected: "abc"
      }
    ],
    call: ->(input) { Eodhd::Validate.required_string!(input[:name], input[:value]) }
  )

  test_raises(
    ".required_string! errors",
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
    call: ->(input) { Eodhd::Validate.required_string!(input[:name], input[:value]) }
  )

  test_equals(
    ".http_url!",
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
    call: ->(input) { Eodhd::Validate.http_url!(input[:name], input[:value]) }
  )

  test_raises(
    ".http_url! errors",
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
    call: ->(input) { Eodhd::Validate.http_url!(input[:name], input[:value]) }
  )

  describe "http_url! error message" do
    it "includes scheme hint" do
      err = assert_raises(ArgumentError) do
        Eodhd::Validate.http_url!("base", "ftp://example.com")
      end
      assert_match(/must start with http:\/\/ or https:\/\//, err.message)
    end
  end
end
