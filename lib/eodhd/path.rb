# frozen_string_literal: true

module Eodhd
  class Path
    class << self
      def exchanges_list
        "exchanges-list.json"
      end

      def eod_data(exchange:, symbol:)
        exchange = Validate.required_string!("exchange", exchange)
        symbol = Validate.required_string!("symbol", symbol)

        exchange = Eodhd::StringUtil.kebab_case(exchange)
        symbol = Eodhd::StringUtil.kebab_case(symbol)

        File.join("eod", "#{symbol}.#{exchange}.json")
      end

      def exchange_symbol_list(exchange_code:, type:)
        exchange_code = Validate.required_string!("exchange_code", exchange_code)
        type = Validate.required_string!("type", type)

        exchange_code = Eodhd::StringUtil.kebab_case(exchange_code)
        type = Eodhd::StringUtil.kebab_case(type)
        type = "unknown" if type.empty?

        File.join("symbols", "#{exchange_code}_#{type}.json")
      end

      def mcd_csv
        File.join("data", "MCD.US.csv")
      end
    end
  end
end
