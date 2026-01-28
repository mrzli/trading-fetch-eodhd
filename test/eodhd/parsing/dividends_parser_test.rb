# frozen_string_literal: true

require_relative "../../test_helper"

require_relative "../../../lib/eodhd/parsing/dividends_parser"

describe Eodhd::DividendsParser do
  it "returns [] for blank input" do
    _(Eodhd::DividendsParser.parse_dividends(" ")).must_equal []
  end

  it "parses dividends and sorts by date" do
    json = <<~JSON
      [
        {
          "date": "2024-01-15",
          "declarationDate": "2024-01-05",
          "recordDate": "2024-01-10",
          "paymentDate": "2024-01-20",
          "period": "Q1",
          "value": 0.5,
          "unadjustedValue": 0.5,
          "currency": "USD"
        },
        {
          "date": "1988-05-16",
          "declarationDate": "1988-04-29",
          "recordDate": "1988-05-20",
          "paymentDate": "1988-06-15",
          "period": null,
          "value": 0.00071,
          "unadjustedValue": 0.07952,
          "currency": "USD"
        }
      ]
    JSON

    dividends = Eodhd::DividendsParser.parse(json, sorted: false)

    expected = [
      Eodhd::DividendsParser::Dividend.new(
        date: Date.iso8601("1988-05-16"),
        declaration_date: Date.iso8601("1988-04-29"),
        record_date: Date.iso8601("1988-05-20"),
        payment_date: Date.iso8601("1988-06-15"),
        period: nil,
        value: 0.00071,
        unadjusted_value: 0.07952,
        currency: "USD"
      ),
      Eodhd::DividendsParser::Dividend.new(
        date: Date.iso8601("2024-01-15"),
        declaration_date: Date.iso8601("2024-01-05"),
        record_date: Date.iso8601("2024-01-10"),
        payment_date: Date.iso8601("2024-01-20"),
        period: "Q1",
        value: 0.5,
        unadjusted_value: 0.5,
        currency: "USD"
      )
    ]

    _(dividends).must_equal expected
  end

  it "handles missing optional dates" do
    json = <<~JSON
      [
        {
          "date": "2024-01-15",
          "declarationDate": null,
          "recordDate": "",
          "paymentDate": "2024-01-20",
          "period": null,
          "value": 0.5,
          "unadjustedValue": 0.5,
          "currency": "USD"
        }
      ]
    JSON

    dividends = Eodhd::DividendsParser.parse(json)

    expected = [
      Eodhd::DividendsParser::Dividend.new(
        date: Date.iso8601("2024-01-15"),
        declaration_date: nil,
        record_date: nil,
        payment_date: Date.iso8601("2024-01-20"),
        period: nil,
        value: 0.5,
        unadjusted_value: 0.5,
        currency: "USD"
      )
    ]

    _(dividends).must_equal expected
  end

  it "raises for invalid JSON" do
    err = _(-> { Eodhd::DividendsParser.parse("not json") }).must_raise(Eodhd::DividendsParser::Error)
    _(err.message).must_match(/Invalid dividends_json/i)
  end

  it "raises if top-level is not an array" do
    _(-> { Eodhd::DividendsParser.parse("{}") }).must_raise(Eodhd::DividendsParser::Error)
  end

  it "raises if entry is not a hash" do
    json = <<~JSON
      ["invalid"]
    JSON

    _(-> { Eodhd::DividendsParser.parse(json) }).must_raise(Eodhd::DividendsParser::Error)
  end

  it "raises for missing required date" do
    json = <<~JSON
      [
        {
          "declarationDate": "2024-01-05",
          "value": 0.5,
          "unadjustedValue": 0.5,
          "currency": "USD"
        }
      ]
    JSON

    _(-> { Eodhd::DividendsParser.parse(json) }).must_raise(Eodhd::DividendsParser::Error)
  end

  it "raises for missing value" do
    json = <<~JSON
      [
        {
          "date": "2024-01-15",
          "unadjustedValue": 0.5,
          "currency": "USD"
        }
      ]
    JSON

    _(-> { Eodhd::DividendsParser.parse(json) }).must_raise(Eodhd::DividendsParser::Error)
  end

  it "raises for missing unadjustedValue" do
    json = <<~JSON
      [
        {
          "date": "2024-01-15",
          "value": 0.5,
          "currency": "USD"
        }
      ]
    JSON

    _(-> { Eodhd::DividendsParser.parse(json) }).must_raise(Eodhd::DividendsParser::Error)
  end

  it "raises for missing currency" do
    json = <<~JSON
      [
        {
          "date": "2024-01-15",
          "value": 0.5,
          "unadjustedValue": 0.5
        }
      ]
    JSON

    _(-> { Eodhd::DividendsParser.parse(json) }).must_raise(Eodhd::DividendsParser::Error)
  end

  it "raises for invalid date format" do
    json = <<~JSON
      [
        {
          "date": "not-a-date",
          "value": 0.5,
          "unadjustedValue": 0.5,
          "currency": "USD"
        }
      ]
    JSON

    _(-> { Eodhd::DividendsParser.parse(json) }).must_raise(Eodhd::DividendsParser::Error)
  end

  it "raises for invalid value" do
    json = <<~JSON
      [
        {
          "date": "2024-01-15",
          "value": "not-a-number",
          "unadjustedValue": 0.5,
          "currency": "USD"
        }
      ]
    JSON

    _(-> { Eodhd::DividendsParser.parse(json) }).must_raise(Eodhd::DividendsParser::Error)
  end
end
