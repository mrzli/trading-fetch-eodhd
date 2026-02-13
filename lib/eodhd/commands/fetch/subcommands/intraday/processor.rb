# frozen_string_literal: true

module Eodhd
  module Commands
    module Fetch
      module Subcommands
        module Intraday
          class Processor
            def initialize(container:)
              @log = container.logger
              @io = container.io
            end

            def process(exchange, symbol)
              exchange_symbol = "#{exchange}/#{symbol}"
              @log.info("[#{exchange_symbol}] Processing raw intraday...")

              fetched_dir = Eodhd::Shared::Path.raw_intraday_fetched_symbol_dir(exchange, symbol)
              fetched_files = list_and_sort_fetched_files(fetched_dir)

              if fetched_files.empty?
                @log.info("[#{exchange_symbol}] No fetched files found")
                return
              end

              fetched_files.each do |file_path|
                process_file(exchange, symbol, file_path)
              end

              @log.info("[#{exchange_symbol}] Completed processing raw intraday")
            end

            private

            def list_and_sort_fetched_files(fetched_dir)
              files = @io.list_relative_files(fetched_dir)
              files
                .filter { |path| path.end_with?(".csv") }
                .sort
            end

            def process_file(exchange, symbol, file_path)
              csv_content = @io.read_text(file_path)
              rows = Eodhd::Shared::Parsing::IntradayCsvParser.parse(csv_content)

              return if rows.empty?

              # Group rows by year-month using binary search
              rows_by_month = Eodhd::Shared::Processing::IntradayGrouper.group_by_month(rows)

              rows_by_month.each do |year_month, month_rows|
                year, month = year_month
                process_month(exchange, symbol, year, month, month_rows)
              end
            end

            def process_month(exchange, symbol, year, month, new_rows)
              processed_file_path = Eodhd::Shared::Path.raw_intraday_processed_month_file(exchange, symbol, year, month)

              existing_rows = load_existing_processed_file(processed_file_path)
              merged_rows = Merger.merge(existing_rows, new_rows)

              write_processed_file(processed_file_path, merged_rows)
            end

            def load_existing_processed_file(file_path)
              return nil unless @io.file_exists?(file_path)

              csv_content = @io.read_text(file_path)
              Eodhd::Shared::Parsing::IntradayCsvParser.parse(csv_content)
            end

            def write_processed_file(file_path, rows)
              return if rows.empty?

              # Convert rows back to CSV format
              csv_lines = ["Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume"]
              rows.each do |row|
                csv_lines << "#{row[:timestamp]},#{row[:gmtoffset]},\"#{row[:datetime]}\",#{row[:open]},#{row[:high]},#{row[:low]},#{row[:close]},#{row[:volume]}"
              end

              csv_content = csv_lines.join("\n") + "\n"
              @io.write_csv(file_path, csv_content)
              @log.info("Wrote #{file_path}")
            end
          end
        end
      end
    end
  end
end
