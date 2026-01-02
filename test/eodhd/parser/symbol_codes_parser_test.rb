# frozen_string_literal: true

require_relative "../../test_helper"

describe Eodhd::SymbolCodesParser do
  it "extracts Code values and ignores invalid rows" do
    log = Eodhd::Logger.new(io: '/dev/null')
    parser = Eodhd::SymbolCodesParser.new(log: log)

    json = JSON.generate([
      { "Code" => "AAA" },
      { "Code" => "  BBB  " },
      { "Code" => "" },
      { "Code" => nil },
      { "code" => "ccc" },
      "not-a-hash"
    ])

    assert_equal ["AAA", "BBB"], parser.codes_from_json(json)
  end

  it "returns [] when JSON is not an array" do
    log = Eodhd::Logger.new(io: '/dev/null')
    parser = Eodhd::SymbolCodesParser.new(log: log)

    json = JSON.generate({ "Code" => "AAA" })

    assert_equal [], parser.codes_from_json(json)
  end

  it "returns [] on invalid JSON" do
    log = Eodhd::Logger.new(io: '/dev/null')
    parser = Eodhd::SymbolCodesParser.new(log: log)

    assert_equal [], parser.codes_from_json("not-json")
  end
end
