# frozen_string_literal: true

require_relative "../../../../../test_helper"

require "json"
require "tmpdir"

describe Eodhd::Commands::Process::Subcommands::Meta::Runner do
  it "generates meta.json with daily and intraday ranges from data" do
    Dir.mktmpdir do |output_dir|
      io = Eodhd::Shared::Io.new(output_dir: output_dir)
      runner = Eodhd::Commands::Process::Subcommands::Meta::Runner.new(log: Logging::NullLogger.new, io: io)

      io.write_csv(
        Eodhd::Shared::Path.data_eod_symbol_file("US", "AAPL"),
        <<~CSV
          Date,Open,High,Low,Close,Volume
          2024-01-05,1,1,1,1,1
          2024-01-02,1,1,1,1,1
          2024-01-08,1,1,1,1,1
        CSV
      )

      io.write_csv(
        Eodhd::Shared::Path.data_intraday_month_file("US", "AAPL", 2024, 1),
        <<~CSV
          Timestamp,Datetime,Open,High,Low,Close,Volume
          1704187800,2024-01-02 09:30:00,1,1,1,1,1
          1704193200,2024-01-02 11:00:00,1,1,1,1,1
        CSV
      )

      io.write_csv(
        Eodhd::Shared::Path.data_intraday_month_file("US", "AAPL", 2024, 2),
        <<~CSV
          Timestamp,Datetime,Open,High,Low,Close,Volume
          1706776200,2024-02-01 09:30:00,1,1,1,1,1
          1706781600,2024-02-01 11:00:00,1,1,1,1,1
        CSV
      )

      io.write_csv(
        Eodhd::Shared::Path.data_intraday_month_file("US", "MSFT", 2024, 1),
        <<~CSV
          Timestamp,Datetime,Open,High,Low,Close,Volume
          1704187800,2024-01-02 09:30:00,1,1,1,1,1
          1704193200,2024-01-02 11:00:00,1,1,1,1,1
        CSV
      )

      runner.process

      result = JSON.parse(io.read_text(Eodhd::Shared::Path.meta_file))

      assert_equal 2, result.size

      aapl = result.find { |row| row["exchange"] == "us" && row["symbol"] == "aapl" }
      refute_nil aapl
      assert_equal({ "from" => "2024-01-02", "to" => "2024-01-08" }, aapl["daily"])
      assert_equal(
        {
          "from" => "2024-01-02T09:30:00+00:00",
          "to" => "2024-02-01T11:00:00+00:00"
        },
        aapl["intraday"]
      )

      msft = result.find { |row| row["exchange"] == "us" && row["symbol"] == "msft" }
      refute_nil msft
      assert_nil msft["daily"]
      assert_equal(
        {
          "from" => "2024-01-02T09:30:00+00:00",
          "to" => "2024-01-02T11:00:00+00:00"
        },
        msft["intraday"]
      )
    end
  end
end
