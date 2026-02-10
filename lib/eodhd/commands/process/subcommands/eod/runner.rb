# frozen_string_literal: true

module Eodhd
  module Commands
    module Process
      module Subcommands
        module Eod
          class Runner
            OUTPUT_HEADERS = ["Date", "Open", "High", "Low", "Close", "Volume"].freeze

            def initialize(log:, io:)
              @log = log
              @io = io
              @processor = Processor.new(log: log)
            end

            def process(force:, parallel:, workers:)
              raw_root = @io.output_path(Eodhd::Shared::Path.raw_eod_dir)
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
                process_exchange(exchange, exchange_dir, force: force, parallel: parallel, workers: workers)
              end
            end

            private

            def process_exchange(exchange, exchange_dir, force:, parallel:, workers:)
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
                process_symbol(data[:exchange], data[:symbol], data[:raw_rel], force: force)
              end
            end

            def process_symbol(exchange, symbol, raw_rel, force:)
              processed_rel = Eodhd::Shared::Path.processed_eod_data(exchange, symbol)
              splits_rel = Eodhd::Shared::Path.splits(exchange, symbol)
              dividends_rel = Eodhd::Shared::Path.dividends(exchange, symbol)

              unless should_process?(
                force: force,
                raw_rel: raw_rel,
                splits_rel: splits_rel,
                dividends_rel: dividends_rel,
                processed_rel: processed_rel
              )
                @log.info("Skipping processed EOD (fresh): #{processed_rel}")
                return
              end

              raw_csv = @io.read_text(raw_rel)
              splits_json = @io.file_exists?(splits_rel) ? @io.read_text(splits_rel) : "[]"
              splits = Eodhd::Parsing::SplitsParser.parse(splits_json)
              dividends_json = @io.file_exists?(dividends_rel) ? @io.read_text(dividends_rel) : "[]"
              dividends = Eodhd::Parsing::DividendsParser.parse(dividends_json)

              data = Parsing::EodCsvParser.parse(raw_csv)
              splits = Shared::SplitsProcessor.process(splits)
              dividends = Shared::DividendsProcessor.process(dividends, data)

              data = Shared::PriceAdjust.apply(data, splits, dividends)
              data = to_output(data)
              processed_csv = to_csv(data)

              saved_path = @io.write_csv(processed_rel, processed_csv)
              @log.info("Wrote #{Util::String.truncate_middle(saved_path)}")
            rescue StandardError => e
              @log.warn("Failed processing EOD for #{exchange}/#{symbol}: #{e.class}: #{e.message}")
            end

            def should_process?(force:, raw_rel:, splits_rel:, dividends_rel:, processed_rel:)
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

            def to_output(data)
              data.map do |row|
                {
                  date: row[:date].iso8601,
                  open: format_price(row[:open]),
                  high: format_price(row[:high]),
                  low: format_price(row[:low]),
                  close: format_price(row[:close]),
                  volume: row[:volume].to_s
                }
              end
            end

            def format_price(price)
              price.round(Shared::Constants::OUTPUT_DECIMALS).to_s
            end

            def to_csv(rows)
              CSV.generate do |out_csv|
                out_csv << OUTPUT_HEADERS

                rows.each do |row|
                  out_csv << [
                    row[:date],
                    row[:open],
                    row[:high],
                    row[:low],
                    row[:close],
                    row[:volume]
                  ]
                end
              end
            end
          end
        end
      end
    end
  end
end
