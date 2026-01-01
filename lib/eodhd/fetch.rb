# frozen_string_literal: true

require "json"

module Eodhd
  module Fetch
    module_function

    def run!
      begin
        cfg = Eodhd::Config.eodhd!
      rescue Eodhd::Config::Error => e
        abort e.message
      end

      api = Eodhd::Api.new(
        base_url: cfg.base_url,
        api_token: cfg.api_token
      )

      io = Eodhd::Io.new(output_dir: cfg.output_dir)

      exchanges_json = api.get_exchanges_list_json!
      exchanges_path = io.save_exchanges_list_json!(json: exchanges_json)
      puts "Wrote #{exchanges_path}"

      exchanges = JSON.parse(exchanges_json)
      unless exchanges.is_a?(Array)
        raise TypeError, "Expected exchanges list JSON to be an Array, got #{exchanges.class}"
      end

      exchange_codes = exchanges.filter_map do |exchange|
        next unless exchange.is_a?(Hash)

        code = exchange["Code"]
        code = code.to_s.strip
        next if code.empty?

        code
      end

      exchange_codes.each do |exchange_code|
        symbols_json = api.get_exchange_symbol_list_json!(exchange_code: exchange_code)
        symbols_path = io.save_exchange_symbol_list_json!(exchange_code: exchange_code, json: symbols_json)
        puts "Wrote #{symbols_path}"
      end

      csv = api.fetch_mcd_csv!

      output_path = io.save_mcd_csv!(csv: csv)
      puts "Wrote #{output_path}"
    end
  end
end
