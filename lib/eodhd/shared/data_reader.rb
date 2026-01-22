# frozen_string_literal: true

require "json"
require "set"

require_relative "../../util"
require_relative "path"

module Eodhd
  class DataReader
    UNSUPPORTED_EXCHANGE_CODES = Set.new(["MONEY"]).freeze

    def initialize(output_dir:)
      @output_dir = Validate.required_string("output_dir", output_dir)
    end

    def exchanges
      exchanges_text = File.read(File.join(@output_dir, Path.exchanges_list))
      exchanges = JSON.parse(exchanges_text)
      exchanges.filter_map do |exchange|
        code = exchange["Code"].to_s.strip
        next if UNSUPPORTED_EXCHANGE_CODES.include?(code)
        code
      end
    end

    def symbols
      symbols_dir = File.join(@output_dir, "symbols")
      return [] unless Dir.exist?(symbols_dir)

      exchanges = Dir.children(symbols_dir).select do |name|
        File.directory?(File.join(symbols_dir, name))
      end

      exchanges.flat_map do |exchange|
        relative_dir = File.join("symbols", exchange)
        absolute_dir = File.join(@output_dir, relative_dir)

        Dir.children(absolute_dir)
          .select { |path| path.end_with?(".json") }
          .sort
          .flat_map do |filename|
            type = File.basename(filename, ".json")
            file_path = File.join(absolute_dir, filename)

            symbols_file_text = File.read(file_path)
            symbol_entries = JSON.parse(symbols_file_text)

            symbol_entries.map do |entry|
              {
                exchange: StringUtil.pascal_case(exchange),
                real_exchange: entry["Exchange"],
                type: type,
                symbol: entry["Code"]
              }
            end
          end
      end
    end

  end
end
