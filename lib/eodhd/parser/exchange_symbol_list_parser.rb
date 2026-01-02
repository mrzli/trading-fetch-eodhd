# frozen_string_literal: true

require "json"

module Eodhd
  module ExchangeSymbolListParser
    module_function

    def group_by_type_from_json(symbols_json)
      symbols = JSON.parse(symbols_json)
      unless symbols.is_a?(Array)
        raise TypeError, "Expected symbols JSON to be an Array, got #{symbols.class}"
      end

      symbols.group_by do |symbol|
        next "unknown" unless symbol.is_a?(Hash)

        raw_type = symbol["Type"] || symbol["type"]
        type = Eodhd::StringUtil.kebab_case(raw_type)
        type = "unknown" if type.empty?
        type
      end
    end
  end
end
