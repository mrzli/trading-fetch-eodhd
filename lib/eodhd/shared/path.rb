# frozen_string_literal: true

require_relative "../../util"

module Eodhd
  class Path
    class << self
      def exchanges_list
        "exchanges-list.json"
      end

      def exchange_symbol_list(exchange, type)
        exchange, type = process_exchange_and_type(exchange, type)
        File.join("symbols", exchange, "#{type}.json")
      end

      def splits(exchange, symbol)
        exchange, symbol = process_exchange_and_symbol(exchange, symbol)
        File.join("meta", exchange, symbol, "splits.json")
      end

      def dividends(exchange, symbol)
        exchange, symbol = process_exchange_and_symbol(exchange, symbol)
        File.join("meta", exchange, symbol, "dividends.json")
      end

      def raw_eod_dir
        File.join("raw", "eod")
      end

      def raw_eod_data(exchange, symbol)
        exchange, symbol = process_exchange_and_symbol(exchange, symbol)
        File.join(raw_eod_dir, exchange, "#{symbol}.csv")
      end

      def processed_eod_data(exchange, symbol)
        exchange, symbol = process_exchange_and_symbol(exchange, symbol)
        File.join("data", "eod", exchange, "#{symbol}.csv")
      end

      def raw_intraday_dir
        File.join("raw", "intraday")
      end

      def raw_intraday_data_dir(exchange, symbol)
        exchange, symbol = process_exchange_and_symbol(exchange, symbol)
        File.join(raw_intraday_dir, exchange, symbol)
      end

      def raw_intraday_data(exchange, symbol, from)
        dir_for_intraday_raw = raw_intraday_data_dir(exchange, symbol)
        from = Validate.integer("from", from)
        from_formatted = DateUtil.seconds_to_datetime(from)

        File.join(dir_for_intraday_raw, "#{from_formatted}.csv")
      end

      def processed_intraday_data_dir(exchange, symbol)
        exchange, symbol = process_exchange_and_symbol(exchange, symbol)
        File.join("data", "intraday", exchange, symbol)
      end

      def processed_intraday_year_month(exchange, symbol, year, month)
        dir = processed_intraday_data_dir(exchange, symbol)
        year = Validate.integer("year", year)
        month = Validate.integer("month", month)
        File.join(dir, "#{year}-#{format('%02d', month)}.csv")
      end

      private

      def process_exchange_and_type(exchange, type)
        exchange = Validate.required_string("exchange", exchange)
        type = Validate.required_string("type", type)

        exchange = StringUtil.kebab_case(exchange)
        type = StringUtil.kebab_case(type)
        type = "unknown" if type.empty?

        [exchange, type]
      end

      def process_exchange_and_symbol(exchange, symbol)
        exchange = Validate.required_string("exchange", exchange)
        symbol = Validate.required_string("symbol", symbol)

        exchange = StringUtil.kebab_case(exchange)
        symbol = StringUtil.kebab_case(symbol)

        [exchange, symbol]
      end
    end
  end
end
