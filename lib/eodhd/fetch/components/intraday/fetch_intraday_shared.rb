# frozen_string_literal: true

require_relative "../../../../util"
# require_relative "../../../shared/path"
require_relative "../../../parsing/intraday_csv_parser"

module Eodhd
  class FetchIntradayShared
    def initialize(container:)
      @log = container.logger
      @api = container.api
    end

    def fetch_intraday_interval_rows(exchange, symbol, from, to)
      symbol_with_exchange = "#{symbol}.#{exchange}"

      from_formatted = DateUtil.seconds_to_datetime(from)
      to_formatted = DateUtil.seconds_to_datetime(to)
      from_to_message_fragment = "(from=#{from_formatted} to=#{to_formatted})"
      @log.info("Fetching intraday CSV: #{symbol_with_exchange} #{from_to_message_fragment}...")

      csv = @api.get_intraday_csv(exchange, symbol, from: from, to: to)

      if csv.to_s.length < MIN_CSV_LENGTH
        @log.info("Stopping intraday history fetch (short CSV, length=#{csv.to_s.length}): #{symbol_with_exchange} #{from_to_message_fragment}")
        return nil
      end

      rows = IntradayCsvParser.parse(csv)
      if rows.empty?
        @log.info("Stopping intraday history fetch (empty CSV): #{symbol_with_exchange} #{from_to_message_fragment}")
        return nil
      end

      return rows
    end
  end
end