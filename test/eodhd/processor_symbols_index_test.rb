# frozen_string_literal: true

require "tmpdir"

require_relative "../test_helper"

describe Eodhd::Processor do
  it "builds exchange -> type -> [codes] index from symbols files" do
    Dir.mktmpdir do |dir|
      log = Eodhd::Logger.new
      cfg = Struct.new(:request_pause_ms, :min_file_age_minutes).new(0, 0)
      api = Object.new
      io = Eodhd::Io.new(output_dir: dir)

      processor = Eodhd::Processor.new(log: log, cfg: cfg, api: api, io: io)

      io.save_json!("symbols/us/common-stock.json", JSON.generate([
        { "Code" => "AAA", "Type" => "Common Stock" },
        { "Code" => "CCC", "Type" => "Common Stock" }
      ]), true)

      io.save_json!("symbols/us/unknown.json", JSON.generate([
        { "Code" => "EEE" },
        "not-a-hash",
        { "Code" => "" }
      ]), true)

      index = processor.symbol_codes_index(["US"])

      assert_equal({
        "US" => {
          "common-stock" => ["AAA", "CCC"],
          "unknown" => ["EEE"]
        }
      }, index)
    end
  end
end
