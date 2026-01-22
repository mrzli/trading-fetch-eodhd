# frozen_string_literal: true

require "json"
require "set"

require_relative "../../util"
require_relative "path"

module Eodhd
  class DataReader
    UNSUPPORTED_EXCHANGE_CODES = Set.new(["MONEY"]).freeze

    def initialize(io:)
      @io = io
    end

    def exchanges
      exchanges_text = @io.read_text(Path.exchanges_list)
      exchanges = JSON.parse(exchanges_text)
      exchanges.filter_map do |exchange|
        code = exchange["Code"].to_s.strip
        next if UNSUPPORTED_EXCHANGE_CODES.include?(code)
        code
      end
    end

    def symbols
      exchanges = @io.list_relative_dirs("symbols")

      exchanges.flat_map do |exchange|
        relative_dir = File.join("symbols", exchange)

        @io
          .list_relative_files(relative_dir)
          .select { |path| path.end_with?(".json") }
          .sort
          .flat_map do |relative_path|
            type = File.basename(relative_path, ".json")

            symbols_file_text = @io.read_text(relative_path)
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
