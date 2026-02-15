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
            def initialize(log:, io:)
              @log = log
              @io = io
            end

            def process
              @log.info("Building meta summary from processed data...")

              daily_ranges = get_daily_ranges()
              # intraday_ranges = get_intraday_ranges()

              # rows = rows_by_key
              #   .values
              #   .sort_by { |row| [row[:exchange], row[:symbol]] }

              # rows_with_daily = rows.count { |row| !row[:daily].nil? }
              # rows_with_intraday = rows.count { |row| !row[:intraday].nil? }

              # if rows.empty?
              #   @log.warn("No processed data found under #{Eodhd::Shared::Path.data_dir}; writing empty summary")
              # else
              #   @log.info(
              #     "Prepared #{rows.size} meta entr#{rows.size == 1 ? 'y' : 'ies'} " \
              #     "(daily: #{rows_with_daily}, intraday: #{rows_with_intraday}, " \
              #     "daily files scanned: #{daily_files_scanned}, intraday files scanned: #{intraday_files_scanned})"
              #   )
              # end

              # output_file = Eodhd::Shared::Path.meta_file
              # @io.write_json(output_file, JSON.generate(rows), true)
              # @log.info("Wrote #{output_file} (#{rows.size} entries)")
            end

            private

            def get_daily_ranges()
              root_dir = Eodhd::Shared::Path.data_eod_dir
              unless @io.dir_exists?(root_dir)
                @log.info("No processed EOD directory found: #{root_dir}")
                return 0
              end

              exchange_dirs = @io.list_relative_dirs(root_dir).sort
              if exchange_dirs.empty?
                @log.info("No EOD exchange directories found under: #{root_dir}")
                return 0
              end

              @log.info("Scanning EOD data in #{exchange_dirs.size} exchange director#{exchange_dirs.size == 1 ? 'y' : 'ies'}")

              files_scanned = 0

              exchange_dirs.each do |exchange_dir|
                exchange = File.basename(exchange_dir)
                symbol_files = @io.list_relative_files(exchange_dir)
                  .filter { |path| path.end_with?(".csv") }
                  .sort

                if symbol_files.empty?
                  @log.info("[#{exchange}] No EOD symbol files found")
                  next
                end

                @log.info("[#{exchange}] Processing #{symbol_files.size} EOD symbol file(s)")

                symbol_files.each do |symbol_file|
                  symbol = File.basename(symbol_file, ".csv")
                  key = row_key(exchange, symbol)
                  rows_by_key[key] ||= base_row(exchange, symbol)
                  rows_by_key[key][:daily] = daily_range(symbol_file)
                  files_scanned += 1
                end
              end

              files_scanned
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

            def collect_intraday_ranges(rows_by_key)
              root_dir = Eodhd::Shared::Path.data_intraday_dir
              unless @io.dir_exists?(root_dir)
                @log.info("No processed intraday directory found: #{root_dir}")
                return 0
              end

              exchange_dirs = @io.list_relative_dirs(root_dir).sort
              if exchange_dirs.empty?
                @log.info("No intraday exchange directories found under: #{root_dir}")
                return 0
              end

              @log.info("Scanning intraday data in #{exchange_dirs.size} exchange director#{exchange_dirs.size == 1 ? 'y' : 'ies'}")

              files_scanned = 0

              exchange_dirs.each do |exchange_dir|
                exchange = File.basename(exchange_dir)
                symbol_dirs = @io.list_relative_dirs(exchange_dir)
                  .sort

                if symbol_dirs.empty?
                  @log.info("[#{exchange}] No intraday symbol directories found")
                  next
                end

                @log.info("[#{exchange}] Processing #{symbol_dirs.size} intraday symbol director#{symbol_dirs.size == 1 ? 'y' : 'ies'}")

                symbol_dirs.each do |symbol_dir|
                  symbol = File.basename(symbol_dir)
                  month_files = @io.list_relative_files(symbol_dir)
                    .filter { |path| path.end_with?(".csv") }
                    .sort

                  @log.info("[#{exchange}/#{symbol}] Found #{month_files.size} intraday month file(s)")

                  key = row_key(exchange, symbol)
                  rows_by_key[key] ||= base_row(exchange, symbol)
                  rows_by_key[key][:intraday] = intraday_range(month_files)
                  files_scanned += month_files.size
                end
              end

              files_scanned
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
