# frozen_string_literal: true

require "json"
require "set"

module Eodhd
  class ExchangesListParser
    DEFAULT_EXCLUDED_EXCHANGE_CODES = Set.new(["MONEY"]).freeze

    def initialize(log:, excluded_exchange_codes: DEFAULT_EXCLUDED_EXCHANGE_CODES)
      @log = log
      @excluded_exchange_codes = excluded_exchange_codes
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

        if @excluded_exchange_codes.include?(code)
          @log.debug("Skipping excluded exchange: #{code}")
          next
        end

        code
      end
    end
  end
end
