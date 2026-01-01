# frozen_string_literal: true

module Eodhd
  class Path
    class << self
      def exchanges_list
        "exchanges-list.json"
      end

      def exchange_symbol_list(exchange_code:)
        exchange_code = Validate.required_string!("exchange_code", exchange_code)
        File.join("symbols", "#{exchange_code}.json")
      end

      def mcd_csv
        File.join("data", "MCD.US.csv")
      end
    end
  end
end
