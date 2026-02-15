# frozen_string_literal: true

require "csv"
require "date"
require "json"

module Eodhd
  module Commands
    module Process
      module Subcommands
        module Meta
          class Runner
            OUTPUT_FILE = "meta.json"

            def initialize(log:, io:)
              @log = log
              @io = io
            end

            def process
              rows_by_key = {}

              collect_daily_ranges(rows_by_key)
              collect_intraday_ranges(rows_by_key)

              rows = rows_by_key
                .values
                .sort_by { |row| [row[:exchange], row[:symbol]] }

              @io.write_json(OUTPUT_FILE, JSON.generate(rows), true)
              @log.info("Wrote #{OUTPUT_FILE} (#{rows.size} entries)")
            end

            private

            def collect_daily_ranges(rows_by_key)
              root_dir = Eodhd::Shared::Path.data_eod_dir
              return unless @io.dir_exists?(root_dir)

              @io.list_relative_dirs(root_dir).sort.each do |exchange_dir|
                exchange = File.basename(exchange_dir)
                @io.list_relative_files(exchange_dir)
                  .filter { |path| path.end_with?(".csv") }
                  .sort
                  .each do |symbol_file|
                    symbol = File.basename(symbol_file, ".csv")
                    key = row_key(exchange, symbol)
                    rows_by_key[key] ||= base_row(exchange, symbol)
                    rows_by_key[key][:daily] = daily_range(symbol_file)
                  end
              end
            end

            def collect_intraday_ranges(rows_by_key)
              root_dir = Eodhd::Shared::Path.data_intraday_dir
              return unless @io.dir_exists?(root_dir)

              @io.list_relative_dirs(root_dir).sort.each do |exchange_dir|
                exchange = File.basename(exchange_dir)
                @io.list_relative_dirs(exchange_dir)
                  .sort
                  .each do |symbol_dir|
                    symbol = File.basename(symbol_dir)
                    month_files = @io.list_relative_files(symbol_dir)
                      .filter { |path| path.end_with?(".csv") }
                      .sort

                    key = row_key(exchange, symbol)
                    rows_by_key[key] ||= base_row(exchange, symbol)
                    rows_by_key[key][:intraday] = intraday_range(month_files)
                  end
              end
            end

            def daily_range(relative_csv_path)
              text = @io.read_text(relative_csv_path)
              parsed = CSV.parse(text, headers: true)

              dates = parsed.filter_map do |row|
                date_str = row["Date"]&.strip
                next if date_str.to_s.empty?
                Date.iso8601(date_str)
              rescue Date::Error
                nil
              end

              return nil if dates.empty?

              from, to = dates.minmax
              { from: from.iso8601, to: to.iso8601 }
            end

            def intraday_range(relative_csv_paths)
              datetimes = relative_csv_paths.flat_map do |relative_csv_path|
                text = @io.read_text(relative_csv_path)
                parsed = CSV.parse(text, headers: true)

                parsed.filter_map do |row|
                  datetime_str = row["Datetime"]&.strip
                  next if datetime_str.to_s.empty?
                  DateTime.parse(datetime_str)
                rescue Date::Error
                  nil
                end
              end

              return nil if datetimes.empty?

              from, to = datetimes.minmax
              { from: from.iso8601, to: to.iso8601 }
            end

            def row_key(exchange, symbol)
              "#{exchange}/#{symbol}"
            end

            def base_row(exchange, symbol)
              {
                symbol: symbol,
                exchange: exchange,
                daily: nil,
                intraday: nil
              }
            end
          end
        end
      end
    end
  end
end
