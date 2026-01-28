# frozen_string_literal: true

require_relative "../../test_helper"

require_relative "../../../lib/eodhd/parsing/splits_parser"

describe Eodhd::SplitsParser do
  it "returns [] for blank input" do
    _(Eodhd::SplitsParser.parse(" ")).must_equal []
  end

  it "parses, sorts by date, and builds rational factors" do
    json = <<~JSON
      [
        {"date":"2024-01-10","split":"4.000000/1.000000"},
        {"date":"2000-06-21","split":"2.000000/1.000000"}
      ]
    JSON

    splits = Eodhd::SplitsParser.parse(json, sorted: false)

    expected = [
      Eodhd::SplitsParser::Split.new(
        date: Date.iso8601("2000-06-21"),
        factor: 2.0
      ),
      Eodhd::SplitsParser::Split.new(
        date: Date.iso8601("2024-01-10"),
        factor: 4.0
      )
    ]

    _(splits).must_equal expected
  end

  it "raises for invalid JSON" do
    err = _(-> { Eodhd::SplitsParser.parse("not json") }).must_raise(Eodhd::SplitsParser::Error)
    _(err.message).must_match(/Invalid splits_json/i)
  end

  it "raises if top-level is not an array" do
    _(-> { Eodhd::SplitsParser.parse("{}") }).must_raise(Eodhd::SplitsParser::Error)
  end

  it "raises for invalid split format" do
    json = <<~JSON
      [{"date":"2024-01-10","split":"4"}]
    JSON

    _(-> { Eodhd::SplitsParser.parse(json) }).must_raise(Eodhd::SplitsParser::Error)
  end

  it "raises for zero/negative split ratio" do
    json = <<~JSON
      [
        {"date":"2024-01-10","split":"0/1"},
        {"date":"2024-01-11","split":"-2/1"},
        {"date":"2024-01-12","split":"2/0"}
      ]
    JSON

    _(-> { Eodhd::SplitsParser.parse(json) }).must_raise(Eodhd::SplitsParser::Error)
  end
end
