# frozen_string_literal: true

module Eodhd
  module Commands
    module Process
      module Subcommands
        module Intraday
          class Runner
            def initialize(log:, io:)
              @log = log
              @io = io
              @processor = Processor.new(log: log)
            end

            def process(force:, parallel:, workers:)
              raw_root = @io.output_path(Eodhd::Shared::Path.raw_intraday_processed_dir)
              unless Dir.exist?(raw_root)
                @log.info("No raw directory found: #{raw_root}")
                return
              end

              exchanges = Dir.children(raw_root)
                .select { |name| Dir.exist?(File.join(raw_root, name)) }
              if exchanges.empty?
                @log.info("No exchange directories found under: #{raw_root}")
                return
              end

              exchanges.each do |exchange|
                exchange_dir = File.join(raw_root, exchange)
                process_exchange(exchange, exchange_dir, force: force, parallel: parallel, workers: workers)
              end
            end

            private

            def process_exchange(exchange, exchange_dir, force:, parallel:, workers:)
              symbols = Dir.children(exchange_dir)
                .select { |name| Dir.exist?(File.join(exchange_dir, name)) }
                .sort
              return if symbols.empty?

              symbol_data_list = symbols.map do |symbol|
                {
                  exchange: exchange,
                  symbol: symbol,
                  symbol_dir: File.join(exchange_dir, symbol)
                }
              end

              Util::ParallelExecutor.execute(symbol_data_list, parallel: parallel, workers: workers) do |symbol_data|
                process_symbol(symbol_data, force: force)
              end
            end

            def process_symbol(symbol_data, force:)
              exchange = symbol_data[:exchange]
              symbol = symbol_data[:symbol]
              symbol_dir = symbol_data[:symbol_dir]

              raw_file_paths = Dir.glob(File.join(symbol_dir, "*.csv"))
                .map { |abs| @io.relative_path(abs) }
                .sort
              return if raw_file_paths.empty?

              splits_rel = Eodhd::Shared::Path.splits(exchange, symbol)
              dividends_rel = Eodhd::Shared::Path.dividends(exchange, symbol)

              splits_json = @io.file_exists?(splits_rel) ? @io.read_text(splits_rel) : nil
              splits = splits_json ? Eodhd::Parsing::SplitsParser.parse(splits_json) : []
              dividends_json = @io.file_exists?(dividends_rel) ? @io.read_text(dividends_rel) : ""
              dividends = Eodhd::Parsing::DividendsParser.parse(dividends_json)

              raw_file_paths.each do |raw_rel|
                filename = File.basename(raw_rel, ".csv")
                
                # Extract year-month from filename (e.g., "2020-01.csv" -> year=2020, month=1)
                match = filename.match(/^(\d{4})-(\d{2})$/)
                unless match
                  @log.warn("Skipping file with invalid name format: #{filename}")
                  next
                end
                
                year = match[1].to_i
                month = match[2].to_i

                processed_rel = Eodhd::Shared::Path.processed_intraday_year_month(exchange, symbol, year, month)

                unless should_process_file?(
                  force: force,
                  raw_rel: raw_rel,
                  splits_rel: splits_rel,
                  dividends_rel: dividends_rel,
                  processed_rel: processed_rel
                )
                  @log.info("Skipping processed intraday (fresh): #{processed_rel}")
                  next
                end

                raw_csv = @io.read_text(raw_rel)
                processed_csv = @processor.process_csv(raw_csv, splits, dividends)
                
                if processed_csv.nil?
                  @log.info("No intraday rows produced for #{exchange}/#{symbol}/#{filename}")
                  next
                end

                saved_path = @io.write_csv(processed_rel, processed_csv)
                @log.info("Wrote #{Util::String.truncate_middle(saved_path)}")
              end
            rescue StandardError => e
              @log.warn("Failed processing intraday for #{exchange}/#{symbol}: #{e.class}: #{e.message}")
            end

            def should_process_file?(force:, raw_rel:, splits_rel:, dividends_rel:, processed_rel:)
              return true if force

              processed_mtime = @io.file_last_updated_at(processed_rel)
              return true if processed_mtime.nil?

              raw_mtime = @io.file_last_updated_at(raw_rel)
              return true if raw_mtime && raw_mtime > processed_mtime

              splits_mtime = @io.file_last_updated_at(splits_rel)
              return true if splits_mtime && splits_mtime > processed_mtime

              dividends_mtime = @io.file_last_updated_at(dividends_rel)
              return true if dividends_mtime && dividends_mtime > processed_mtime

              false
            end
          end
        end
      end
    end
  end
end
