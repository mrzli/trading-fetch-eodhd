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

  end
end
