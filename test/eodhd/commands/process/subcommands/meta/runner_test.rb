# frozen_string_literal: true

require_relative "../../../../../test_helper"

require "json"
require "tmpdir"

describe Eodhd::Commands::Process::Subcommands::Meta::Runner do
  it "returns daily ranges as array of exchange/symbol/daily_range using first and last rows" do
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
        Eodhd::Shared::Path.data_eod_symbol_file("US", "MSFT"),
        <<~CSV
          Date,Open,High,Low,Close,Volume
          2024-02-10,1,1,1,1,1
          2024-02-11,1,1,1,1,1
        CSV
      )

      result = runner.send(:get_daily_ranges)

      assert_equal 2, result.size

      aapl = result.find { |row| row[:exchange] == "us" && row[:symbol] == "aapl" }
      refute_nil aapl
      assert_equal({ from: "2024-01-05", to: "2024-01-08" }, aapl[:daily_range])

      msft = result.find { |row| row[:exchange] == "us" && row[:symbol] == "msft" }
      refute_nil msft
      assert_equal({ from: "2024-02-10", to: "2024-02-11" }, msft[:daily_range])
    end
  end

  it "raises when a daily csv has no data rows" do
    Dir.mktmpdir do |output_dir|
      io = Eodhd::Shared::Io.new(output_dir: output_dir)
      runner = Eodhd::Commands::Process::Subcommands::Meta::Runner.new(log: Logging::NullLogger.new, io: io)

      io.write_csv(
        Eodhd::Shared::Path.data_eod_symbol_file("US", "AAPL"),
        <<~CSV
          Date,Open,High,Low,Close,Volume
        CSV
      )

      err = _ { runner.send(:get_daily_ranges) }
        .must_raise(Eodhd::Commands::Process::Subcommands::Meta::Runner::Error)
      _(err.message).must_match(/no data rows/i)
    end
  end
end
