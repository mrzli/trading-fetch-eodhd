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

      # Meta - start
      def splits(exchange, symbol)
        exchange, symbol = process_exchange_and_symbol(exchange, symbol)
        File.join("meta", exchange, symbol, "splits.json")
      end

      def dividends(exchange, symbol)
        exchange, symbol = process_exchange_and_symbol(exchange, symbol)
        File.join("meta", exchange, symbol, "dividends.json")
      end
      # Meta - end

      # Raw eod - start
      def raw_eod_dir
        File.join("raw", "eod")
      end

      def raw_eod_data(exchange, symbol)
        exchange, symbol = process_exchange_and_symbol(exchange, symbol)
        File.join(raw_eod_dir, exchange, "#{symbol}.csv")
      end
      # Raw eod - end

      # Raw intraday - start
      def raw_intraday_dir
        File.join("raw", "intraday")
      end

      def raw_intraday_fetched_dir
        File.join(raw_intraday_dir, "fetched")
      end

      def raw_intraday_fetched_symbol_data_dir(exchange, symbol)
        exchange, symbol = process_exchange_and_symbol(exchange, symbol)
        File.join(raw_intraday_fetched_dir, exchange, symbol)
      end

      def raw_intraday_fetched_symbol_data(exchange, symbol, from, to)
        dir_for_intraday_raw = raw_intraday_fetched_symbol_data_dir(exchange, symbol)

        from = Util::Validate.integer("from", from)
        from_formatted = Util::DateUtil.seconds_to_datetime(from)

        to = Util::Validate.integer("to", to)
        to_formatted = Util::DateUtil.seconds_to_datetime(to)

        File.join(dir_for_intraday_raw, "#{from_formatted}__#{to_formatted}.csv")
      end

      def raw_intraday_processed_dir
        File.join(raw_intraday_dir, "processed")
      end

      def raw_intraday_processed_symbol_data_dir(exchange, symbol)
        exchange, symbol = process_exchange_and_symbol(exchange, symbol)
        File.join(raw_intraday_processed_dir, exchange, symbol)
      end

      def raw_intraday_processed_symbol_year_month(exchange, symbol, year, month)
        dir = raw_intraday_processed_symbol_data_dir(exchange, symbol)
        year = Util::Validate.integer("year", year)
        month = Util::Validate.integer("month", month)
        File.join(dir, "#{year}-#{format('%02d', month)}.csv")
      end
      # Raw intraday - end

      # Processed eod - start
      def processed_eod_data(exchange, symbol)
        exchange, symbol = process_exchange_and_symbol(exchange, symbol)
        File.join("data", "eod", exchange, "#{symbol}.csv")
      end
      # Processed eod - end

      # Processed intraday - start
      def processed_intraday_data_dir(exchange, symbol)
        exchange, symbol = process_exchange_and_symbol(exchange, symbol)
        File.join("data", "intraday", exchange, symbol)
      end

      def processed_intraday_year_month(exchange, symbol, year, month)
        dir = processed_intraday_data_dir(exchange, symbol)
        year = Util::Validate.integer("year", year)
        month = Util::Validate.integer("month", month)
        File.join(dir, "#{year}-#{format('%02d', month)}.csv")
      end
      # Processed intraday - end

      private

      def process_exchange_and_type(exchange, type)
        exchange = Util::Validate.required_string("exchange", exchange)
        type = Util::Validate.required_string("type", type)

        exchange = Util::StringUtil.kebab_case(exchange)
        type = Util::StringUtil.kebab_case(type)
        type = "unknown" if type.empty?

        [exchange, type]
      end

      def process_exchange_and_symbol(exchange, symbol)
        exchange = Util::Validate.required_string("exchange", exchange)
        symbol = Util::Validate.required_string("symbol", symbol)

        exchange = Util::StringUtil.kebab_case(exchange)
        symbol = Util::StringUtil.kebab_case(symbol)

        [exchange, symbol]
      end
    end
  end
end
