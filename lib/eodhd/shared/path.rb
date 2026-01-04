# frozen_string_literal: true

module Eodhd
  class Path
    class << self
      def exchanges_list
        "exchanges-list.json"
      end

      def exchange_symbol_list(exchange, type)
        exchange = Validate.required_string!("exchange", exchange)
        type = Validate.required_string!("type", type)

        exchange = StringUtil.kebab_case(exchange)
        type = StringUtil.kebab_case(type)
        type = "unknown" if type.empty?

        File.join("symbols", exchange, "#{type}.json")
      end

      def raw_eod_data(exchange, symbol)
        exchange = Validate.required_string!("exchange", exchange)
        symbol = Validate.required_string!("symbol", symbol)

        exchange = StringUtil.kebab_case(exchange)
        symbol = StringUtil.kebab_case(symbol)

        File.join("raw", "eod", exchange, "#{symbol}.csv")
      end

      def raw_intraday_data_dir(exchange, symbol)
        exchange = Validate.required_string!("exchange", exchange)
        symbol = Validate.required_string!("symbol", symbol)

        exchange = StringUtil.kebab_case(exchange)
        symbol = StringUtil.kebab_case(symbol)

        File.join("raw", "intraday", exchange, symbol)
      end

      def raw_intraday_data(exchange, symbol, from)
        dir_for_intraday_raw = raw_intraday_data_dir(exchange, symbol)

        from = Validate.integer!("from", from)

        from_formatted = DateUtil.seconds_to_datetime(from)

        File.join(dir_for_intraday_raw, "#{from_formatted}.csv")
      end

      def splits(exchange, symbol)
        dir_for_intraday = raw_intraday_data_dir(exchange, symbol)

        File.join(dir_for_intraday, "meta", "splits.json")
      end
    end
  end
end
