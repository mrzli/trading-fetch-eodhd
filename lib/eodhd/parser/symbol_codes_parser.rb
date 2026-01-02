# frozen_string_literal: true

require "json"

module Eodhd
  class SymbolCodesParser
    def initialize(log:)
      @log = log
    end

    def codes_from_json(symbols_json, source: nil)
      parsed = JSON.parse(symbols_json)
      unless parsed.is_a?(Array)
        @log.warn("Expected symbols JSON to be an Array#{source_suffix(source)}") if @log.respond_to?(:warn)
        return []
      end

      parsed.filter_map do |row|
        next unless row.is_a?(Hash)

        code = row["Code"].to_s.strip
        next if code.empty?

        code
      end
    rescue JSON::ParserError => e
      @log.warn("Failed to parse symbols JSON#{source_suffix(source)}: #{e.message}") if @log.respond_to?(:warn)
      []
    end

    private

    def source_suffix(source)
      source_str = source.to_s.strip
      return "" if source_str.empty?
      ": #{source_str}"
    end
  end
end
