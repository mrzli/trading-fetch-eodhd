# frozen_string_literal: true

require_relative "../test_helper"

describe Eodhd::ExchangesListParser do
  it "extracts exchange codes and skips excluded" do
    log = Eodhd::Logger.new
    parser = Eodhd::ExchangesListParser.new(
      log: log,
      excluded_exchange_codes: Set.new(["MONEY"])
    )

    json = JSON.generate(
      [
        { "Code" => "US" },
        { "Code" => "  XETRA_GERMANY  " },
        { "Code" => "MONEY" },
        { "Code" => "" },
        "not-a-hash"
      ]
    )

    assert_equal ["US", "XETRA_GERMANY"], parser.exchange_codes_from_json(json)
  end
end
