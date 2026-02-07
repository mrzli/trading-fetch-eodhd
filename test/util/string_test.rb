# frozen_string_literal: true

require_relative "../test_helper"


describe Util::String do
  test_equals(
    ".kebab_case",
    [
      {
        description: "snake_case",
        input: "snake_case_value",
        expected: "snake-case-value"
      },
      {
        description: "spaces",
        input: "hello world",
        expected: "hello-world"
      },
      {
        description: "kebab already",
        input: "already-kebab",
        expected: "already-kebab"
      },
      {
        description: "camelCase",
        input: "camelCaseValue",
        expected: "camel-case-value"
      },
      {
        description: "PascalCase",
        input: "PascalCaseValue",
        expected: "pascal-case-value"
      },
      {
        description: "acronym boundary",
        input: "HTTPServerError",
        expected: "http-server-error"
      },
      {
        description: "mixed separators",
        input: "  hello_world--Again  ",
        expected: "hello-world-again"
      },
      {
        description: "nil becomes empty",
        input: nil,
        expected: ""
      },
      {
        description: "blank becomes empty",
        input: "   ",
        expected: ""
      }
    ],
    call: ->(input) { Util::String.kebab_case(input) }
  )

  test_equals(
    ".truncate_middle",
    [
      {
        description: "short string unchanged (default)",
        input: {
          str: "short"
        },
        expected: "short"
      },
      {
        description: "exactly at limit unchanged (default)",
        input: {
          str: "a" * 80
        },
        expected: "a" * 80
      },
      {
        description: "one over limit truncated (default)",
        input: {
          str: "a" * 81
        },
        expected: "#{'a' * 38}...#{'a' * 39}"
      },
      {
        description: "long path truncated with ellipsis (default)",
        input: {
          str: "/Users/mrzli/projects/data/eodhd/raw/intraday/fetched/us/aapl/2025-01-01_00-00-00__2025-03-12_20-43-00.csv"
        },
        expected: "/Users/mrzli/projects/data/eodhd/raw/i...01-01_00-00-00__2025-03-12_20-43-00.csv"
      },
      {
        description: "empty string unchanged (default)",
        input: {
          str: ""
        },
        expected: ""
      },
      {
        description: "custom max_length=50",
        input: {
          str: "Hello World! This is a long string that needs truncation.",
          max_length: 50
        },
        expected: "Hello World! This is a ...g that needs truncation."
      },
      {
        description: "custom max_length=20",
        input: {
          str: "This is a very long string",
          max_length: 20
        },
        expected: "This is ...ng string"
      },
      {
        description: "short string with custom max_length",
        input: {
          str: "short",
          max_length: 10
        },
        expected: "short"
      }
    ],
    call: ->(input) {
      if input.key?(:max_length)
        Util::String.truncate_middle(input[:str], input[:max_length])
      else
        Util::String.truncate_middle(input[:str])
      end
    }
  )
end
