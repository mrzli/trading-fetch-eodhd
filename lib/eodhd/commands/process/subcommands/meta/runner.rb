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
            class Error < StandardError; end
            SYMBOL_PROGRESS_LOG_EVERY = 100

            def initialize(log:, io:)
              @log = log
              @io = io
            end

            def process(parallel:, workers:)
              @log.info("Building meta summary from processed data...")

              daily_ranges = get_daily_ranges(parallel: parallel, workers: workers)
              intraday_ranges = get_intraday_ranges(parallel: parallel, workers: workers)

              rows = combine_ranges(daily_ranges, intraday_ranges)

              rows_with_daily = rows.count { |row| !row[:daily].nil? }
              rows_with_intraday = rows.count { |row| !row[:intraday].nil? }

              if rows.empty?
                @log.warn("No processed data found under #{Eodhd::Shared::Path.data_dir}; writing empty summary")
              else
                @log.info(
                  "Prepared #{rows.size} meta entr#{rows.size == 1 ? 'y' : 'ies'} " \
                  "(daily: #{rows_with_daily}, intraday: #{rows_with_intraday})"
                )
              end

              output_file = Eodhd::Shared::Path.meta_file
              @io.write_json(output_file, JSON.generate(rows), true)
              @log.info("Wrote #{output_file} (#{rows.size} entries)")
            end

            private

            def get_daily_ranges(parallel:, workers:)
              root_dir = Eodhd::Shared::Path.data_eod_dir
              unless @io.dir_exists?(root_dir)
                @log.info("No processed EOD directory found: #{root_dir}")
                return []
              end

              exchange_dirs = @io.list_relative_dirs(root_dir).sort
              if exchange_dirs.empty?
                @log.info("No EOD exchange directories found under: #{root_dir}")
                return []
              end

              @log.info("Scanning EOD data in #{exchange_dirs.size} exchange director#{exchange_dirs.size == 1 ? 'y' : 'ies'}")

              results = []

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

                symbol_items = symbol_files.each_with_index.map do |symbol_file, index|
                  {
                    symbol_file: symbol_file,
                    symbol_number: index + 1,
                    total_symbols: symbol_files.size
                  }
                end

                exchange_results = Util::ParallelExecutor.map(symbol_items, parallel: parallel, workers: workers) do |item|
                  symbol = File.basename(item[:symbol_file], ".csv")
                  log_symbol_progress(exchange, item[:symbol_number], item[:total_symbols], symbol, "EOD symbol file(s)")

                  {
                    exchange: exchange,
                    symbol: symbol,
                    daily_range: daily_range(item[:symbol_file])
                  }
                end

                results.concat(exchange_results)
              end

              results
            end

            def daily_range(relative_csv_path)
              text = @io.read_text(relative_csv_path)
              parsed = CSV.parse(text, headers: true)

              rows = parsed.each.to_a
              if rows.empty?
                raise Error, "CSV contains no data rows: #{relative_csv_path}"
              end

              from = Date.iso8601(rows.first["Date"].to_s.strip)
              to = Date.iso8601(rows.last["Date"].to_s.strip)
              { from: from.iso8601, to: to.iso8601 }
            end

            def get_intraday_ranges(parallel:, workers:)
              root_dir = Eodhd::Shared::Path.data_intraday_dir
              unless @io.dir_exists?(root_dir)
                @log.info("No processed intraday directory found: #{root_dir}")
                return []
              end

              exchange_dirs = @io.list_relative_dirs(root_dir).sort
              if exchange_dirs.empty?
                @log.info("No intraday exchange directories found under: #{root_dir}")
                return []
              end

              @log.info("Scanning intraday data in #{exchange_dirs.size} exchange director#{exchange_dirs.size == 1 ? 'y' : 'ies'}")

              results = []

              exchange_dirs.each do |exchange_dir|
                exchange = File.basename(exchange_dir)
                symbol_dirs = @io.list_relative_dirs(exchange_dir)
                  .sort

                if symbol_dirs.empty?
                  @log.info("[#{exchange}] No intraday symbol directories found")
                  next
                end

                @log.info("[#{exchange}] Processing #{symbol_dirs.size} intraday symbol director#{symbol_dirs.size == 1 ? 'y' : 'ies'}")

                symbol_items = symbol_dirs.each_with_index.map do |symbol_dir, index|
                  {
                    symbol_dir: symbol_dir,
                    symbol_number: index + 1,
                    total_symbols: symbol_dirs.size
                  }
                end

                exchange_results = Util::ParallelExecutor.map(symbol_items, parallel: parallel, workers: workers) do |item|
                  symbol_dir = item[:symbol_dir]
                  symbol = File.basename(symbol_dir)
                  month_files = @io.list_relative_files(symbol_dir)
                    .filter { |path| path.end_with?(".csv") }
                    .sort

                  @log.info("[#{exchange}/#{symbol}] Found #{month_files.size} intraday month file(s)")
                  log_symbol_progress(exchange, item[:symbol_number], item[:total_symbols], symbol, "intraday symbol director#{item[:total_symbols] == 1 ? 'y' : 'ies'}")
                  next nil if month_files.empty?

                  range = intraday_range(month_files)

                  {
                    exchange: exchange,
                    symbol: symbol,
                    intraday_range: range
                  }
                end

                results.concat(exchange_results.compact)
              end

              results
            end

            def log_symbol_progress(exchange, symbol_number, total_symbols, symbol, noun)
              return unless (symbol_number % SYMBOL_PROGRESS_LOG_EVERY).zero? || symbol_number == total_symbols

              @log.info("[#{exchange}] Processed #{symbol_number}/#{total_symbols} #{noun} (current: #{symbol})")
            end

            def intraday_range(relative_csv_paths)
              sorted_paths = relative_csv_paths.sort
              return nil if sorted_paths.empty?

              first_file = sorted_paths.first
              first_rows = CSV.parse(@io.read_text(first_file), headers: true).each.to_a
              if first_rows.empty?
                @log.warn("Intraday first file has no data rows: #{first_file}")
                return nil
              end
              from_string = first_rows.first["Datetime"].to_s.strip
              if from_string.empty?
                @log.warn("Intraday first file has empty datetime in first row: #{first_file}")
                return nil
              end
              from = DateTime.parse(from_string)

              last_file = sorted_paths.last
              last_rows = CSV.parse(@io.read_text(last_file), headers: true).each.to_a
              if last_rows.empty?
                @log.warn("Intraday last file has no data rows: #{last_file}")
                return nil
              end
              to_string = last_rows.last["Datetime"].to_s.strip
              if to_string.empty?
                @log.warn("Intraday last file has empty datetime in last row: #{last_file}")
                return nil
              end
              to = DateTime.parse(to_string)

              { from: from.iso8601, to: to.iso8601 }
            end

            def combine_ranges(daily_ranges, intraday_ranges)
              rows_by_key = {}

              daily_ranges.each do |entry|
                exchange = entry[:exchange]
                symbol = entry[:symbol]
                key = row_key(exchange, symbol)

                rows_by_key[key] ||= base_row(exchange, symbol)
                rows_by_key[key][:daily] = entry[:daily_range]
              end

              intraday_ranges.each do |entry|
                exchange = entry[:exchange]
                symbol = entry[:symbol]
                key = row_key(exchange, symbol)

                rows_by_key[key] ||= base_row(exchange, symbol)
                rows_by_key[key][:intraday] = entry[:intraday_range]
              end

              rows_by_key
                .values
                .sort_by { |row| [row[:exchange], row[:symbol]] }
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
