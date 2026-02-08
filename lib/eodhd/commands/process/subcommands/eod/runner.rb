# frozen_string_literal: true

module Eodhd
  module Commands
    module Process
      module Subcommands
        module Eod
          class Runner
            def initialize(log:, io:)
              @log = log
              @io = io
              @processor = Processor.new(log: log)
            end

            def process(parallel:, workers:)
              raw_root = @io.output_path(Shared::Path.raw_eod_dir)
              unless Dir.exist?(raw_root)
                @log.info("No raw EOD directory found: #{raw_root}")
                return
              end

              exchanges = Dir.children(raw_root)
                .filter { |name| Dir.exist?(File.join(raw_root, name)) }
              if exchanges.empty?
                @log.info("No exchange directories found under: #{raw_root}")
                return
              end

              exchanges.each do |exchange|
                exchange_dir = File.join(raw_root, exchange)
                process_exchange(exchange, exchange_dir, parallel: parallel, workers: workers)
              end
            end

            private

            def should_process?(raw_rel:, splits_rel:, processed_rel:)
              processed_mtime = @io.file_last_updated_at(processed_rel)
              return true if processed_mtime.nil?

              raw_mtime = @io.file_last_updated_at(raw_rel)
              return true if raw_mtime && raw_mtime > processed_mtime

              splits_mtime = @io.file_last_updated_at(splits_rel)
              return true if splits_mtime && splits_mtime > processed_mtime

              false
            end

            def process_exchange(exchange, exchange_dir, parallel:, workers:)
              raw_abs_files = Dir.glob(File.join(exchange_dir, "*.csv")).sort
              return if raw_abs_files.empty?

              file_data = raw_abs_files.map do |raw_abs|
                {
                  exchange: exchange,
                  symbol: File.basename(raw_abs, ".csv"),
                  raw_rel: @io.relative_path(raw_abs)
                }
              end

              Util::ParallelExecutor.execute(file_data, parallel: parallel, workers: workers) do |data|
                process_symbol(data[:exchange], data[:symbol], data[:raw_rel])
              end
            end

            def process_symbol(exchange, symbol, raw_rel)
              processed_rel = Shared::Path.processed_eod_data(exchange, symbol)
              splits_rel = Shared::Path.splits(exchange, symbol)
              dividends_rel = Shared::Path.dividends(exchange, symbol)

              unless should_process?(raw_rel: raw_rel, splits_rel: splits_rel, processed_rel: processed_rel)
                @log.info("Skipping processed EOD (fresh): #{processed_rel}")
                return
              end

              raw_csv = @io.read_text(raw_rel)
              splits_json = @io.file_exists?(splits_rel) ? @io.read_text(splits_rel) : ""
              splits = Parsing::SplitsParser.parse(splits_json)
              dividends_json = @io.file_exists?(dividends_rel) ? @io.read_text(dividends_rel) : ""
              dividends = Parsing::DividendsParser.parse(dividends_json)

              processed_csv = @processor.process_csv(raw_csv, splits, dividends)
              saved_path = @io.write_csv(processed_rel, processed_csv)
              @log.info("Wrote #{Util::String.truncate_middle(saved_path)}")
            rescue StandardError => e
              @log.warn("Failed processing EOD for #{exchange}/#{symbol}: #{e.class}: #{e.message}")
            end
          end
        end
      end
    end
  end
end
