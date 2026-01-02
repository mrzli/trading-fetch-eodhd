# frozen_string_literal: true

require "json"

module Eodhd
  class ExchangeSymbolListParser
    def initialize(log:)
      @log = log
    end

    def group_by_type_from_json(symbols_json)
      symbols = JSON.parse(symbols_json)
      unless symbols.is_a?(Array)
        raise TypeError, "Expected symbols JSON to be an Array, got #{symbols.class}"
      end

      symbols.group_by do |symbol|
        unless symbol.is_a?(Hash)
          @log.debug("Skipping non-hash symbol row: #{symbol.class}") if @log.respond_to?(:debug)
          next "unknown"
        end

        raw_type = symbol["Type"] || symbol["type"]
        type = StringUtil.kebab_case(raw_type)
        type = "unknown" if type.empty?
        type
      end
    end
  end
end
