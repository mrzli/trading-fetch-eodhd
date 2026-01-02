# frozen_string_literal: true

require_relative "../../test_helper"

describe Eodhd::ExchangesListParser do
  it "extracts exchange codes and skips excluded" do
    log = Eodhd::Logger.new

    json = JSON.generate(
      [
        { "Code" => "US" },
        { "Code" => "  XETRA_GERMANY  " },
        { "Code" => "MONEY" },
        { "Code" => "" },
        "not-a-hash"
      ]
    )

    assert_equal ["US", "XETRA_GERMANY"], Eodhd::ExchangesListParser.exchange_codes_from_json(
      json,
      log,
      Set.new(["MONEY"])
    )
  end
end
