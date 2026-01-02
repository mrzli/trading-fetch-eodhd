# frozen_string_literal: true

require_relative "../../test_helper"

describe Eodhd::ExchangeSymbolListParser do
  it "groups symbols by kebab-cased Type" do
    json = JSON.generate(
      [
        { "Code" => "AAA", "Type" => "Common Stock" },
        { "Code" => "BBB", "Type" => "ETF" },
        { "Code" => "CCC", "Type" => "Common Stock" },
        { "Code" => "DDD", "type" => "MutualFund" },
        { "Code" => "EEE" },
        "not-a-hash"
      ]
    )

    grouped = Eodhd::ExchangeSymbolListParser.group_by_type_from_json(json)

    assert_equal ["common-stock", "etf", "mutual-fund", "unknown"].sort, grouped.keys.sort
    assert_equal ["AAA", "CCC"], grouped["common-stock"].map { |row| row["Code"] }
  end
end
