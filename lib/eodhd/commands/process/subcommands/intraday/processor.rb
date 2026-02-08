# frozen_string_literal: true

require "csv"
require "date"

module Eodhd
  module Commands
    module Process
      module Subcommands
        module Intraday
          class Processor
            OUTPUT_HEADERS = ["Timestamp", "Datetime", "Open", "High", "Low", "Close", "Volume"].freeze

            class Error < StandardError; end

            def initialize(log:)
              @log = log
            end

            def process_csv(raw_csv, splits, dividends)
              parsed = Eodhd::Parsing::IntradayCsvParser.parse(raw_csv)
              if parsed.empty?
                @log.info("Skipped empty intraday CSV with size #{raw_csv.bytesize} bytes")
                return nil
              end

              first = parsed.first
              last = parsed.last
              @log.info("Parsed intraday CSV for interval #{first[:datetime]} - #{last[:datetime]} with #{parsed.size} rows")

              splits = Eodhd::Commands::Process::Shared::SplitsProcessor.process(splits)
              dividends = Eodhd::Commands::Process::Shared::DividendsProcessor.process(dividends, parsed)

              @log.info("Processed splits and dividends.")

              data = Eodhd::Commands::Process::Shared::PriceAdjust.apply(parsed, splits, dividends)

              @log.info("Applied price adjustments.")

              output = to_output(data)
              csv = to_csv(output)

              @log.info("Generated CSV with #{output.size} rows.")

              csv
            rescue Eodhd::Parsing::IntradayCsvParser::Error => e
              raise Error, e.message
            rescue ArgumentError => e
              raise Error, e.message
            end

            private

            def to_output(data)
              data.map do |row|
                {
                  timestamp: row[:timestamp].to_s,
                  datetime: row[:datetime],
                  open: format_price(row[:open]),
                  high: format_price(row[:high]),
                  low: format_price(row[:low]),
                  close: format_price(row[:close]),
                  volume: row[:volume].to_s
                }
              end
            end

            def format_price(price)
              price.round(Eodhd::Commands::Process::Shared::Constants::OUTPUT_DECIMALS).to_s
            end

            def to_csv(rows)
              CSV.generate do |out_csv|
                out_csv << OUTPUT_HEADERS

                rows.each do |row|
                  out_csv << [
                    row[:timestamp],
                    row[:datetime],
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
