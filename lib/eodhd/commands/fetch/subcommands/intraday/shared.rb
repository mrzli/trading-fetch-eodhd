# frozen_string_literal: true

# require_relative "../../../../shared/path"

module Eodhd
  module Commands
    module Fetch
      module Subcommands
        module Intraday
          class Shared
            MIN_CSV_LENGTH = 20

            def initialize(container:)
              @log = container.logger
              @api = container.api
            end

            def fetch_intraday_interval_csv(exchange, symbol, from, to)
              exchange_symbol = "#{exchange}/#{symbol}"

              from_formatted = Util::Date.seconds_to_datetime(from)
              to_formatted = Util::Date.seconds_to_datetime(to)
              from_to_message_fragment = "(from=#{from_formatted} to=#{to_formatted})"
              @log.info("[#{exchange_symbol}] Fetching intraday CSV #{from_to_message_fragment}...")

              csv = @api.get_intraday_csv(exchange, symbol, from: from, to: to)

              if csv.to_s.length < MIN_CSV_LENGTH
                @log.info("[#{exchange_symbol}] Stopping intraday history fetch (short CSV, length=#{csv.to_s.length}) #{from_to_message_fragment}")
                return nil
              end

              return csv
            end

          end
        end
      end
    end
  end
end
