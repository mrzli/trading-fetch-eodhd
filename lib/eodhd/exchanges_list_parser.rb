# frozen_string_literal: true

require "json"

module Eodhd
  EXCLUDED_EXCHANGE_CODES = Set.new(["MONEY"]).freeze

  class ExchangesListParser
    def initialize(log:)
      @log = log
    end

    def exchange_codes_from_json(exchanges_json)
      exchanges = JSON.parse(exchanges_json)
      unless exchanges.is_a?(Array)
        raise TypeError, "Expected exchanges list JSON to be an Array, got #{exchanges.class}"
      end

      exchanges.filter_map do |exchange|
        next unless exchange.is_a?(Hash)

        code = exchange["Code"].to_s.strip
        next if code.empty?

        if EXCLUDED_EXCHANGE_CODES.include?(code)
          @log.debug("Skipping excluded exchange: #{code}")
          next
        end

        code
      end
    end
  end
end
