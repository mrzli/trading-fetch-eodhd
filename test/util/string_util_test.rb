# frozen_string_literal: true

require_relative "../test_helper"

require_relative "../../lib/util"

describe Eodhd::StringUtil do
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
    call: ->(input) { Eodhd::StringUtil.kebab_case(input) }
  )
end
