# frozen_string_literal: true

require "json"
require "set"

module Eodhd
  module Shared
    class DataReader
      UNSUPPORTED_EXCHANGE_CODES = Set.new(["MONEY"]).freeze

      def initialize(io:)
        @io = io
      end

      def exchanges
        exchanges_text = @io.read_text(Path.exchanges_file)
        exchanges = JSON.parse(exchanges_text)
        exchanges.filter_map do |exchange|
          code = exchange["Code"].to_s.strip
          next if UNSUPPORTED_EXCHANGE_CODES.include?(code)
          code
        end
          .sort
      end

      def symbols
        exchanges.flat_map do |exchange|
          relative_dir = File.join(Path.symbols_dir, Util::String.kebab_case(exchange))
          
          next [] unless @io.dir_exists?(relative_dir)

          @io
            .list_relative_files(relative_dir)
            .filter { |path| path.end_with?(".json") }
            .sort
            .flat_map do |relative_path|
              type = File.basename(relative_path, ".json")

              symbols_file_text = @io.read_text(relative_path)
              symbol_entries = JSON.parse(symbols_file_text)

              symbol_entries.map do |entry|
                {
                  exchange: exchange,
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
end
