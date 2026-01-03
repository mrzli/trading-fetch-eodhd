# frozen_string_literal: true

module Eodhd
  class Path
    class << self
      def exchanges_list
        "exchanges-list.json"
      end

      def exchange_symbol_list(exchange_code, type)
        exchange_code = Validate.required_string!("exchange_code", exchange_code)
        type = Validate.required_string!("type", type)

        exchange_code = StringUtil.kebab_case(exchange_code)
        type = StringUtil.kebab_case(type)
        type = "unknown" if type.empty?

        File.join("symbols", exchange_code, "#{type}.json")
      end

      def eod_data(exchange, symbol)
        exchange = Validate.required_string!("exchange", exchange)
        symbol = Validate.required_string!("symbol", symbol)

        exchange = StringUtil.kebab_case(exchange)
        symbol = StringUtil.kebab_case(symbol)

        File.join("eod", exchange, "#{symbol}.csv")
      end

      def intraday_data_dir(exchange, symbol)
        exchange = Validate.required_string!("exchange", exchange)
        symbol = Validate.required_string!("symbol", symbol)

        exchange = StringUtil.kebab_case(exchange)
        symbol = StringUtil.kebab_case(symbol)

        File.join("intraday", exchange, symbol)
      end

      def intraday_data(exchange, symbol, from)
        exchange = Validate.required_string!("exchange", exchange)
        symbol = Validate.required_string!("symbol", symbol)
        from = Validate.integer!("from", from)

        exchange = StringUtil.kebab_case(exchange)
        symbol = StringUtil.kebab_case(symbol)

        from_formatted = DateUtil.utc_compact_datetime(from)
        File.join("intraday", exchange, symbol, "raw", "#{from_formatted}.csv")
      end
    end
  end
end
