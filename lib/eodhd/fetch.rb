# frozen_string_literal: true

require "json"

module Eodhd
  module Fetch
    module_function

    def run!
      log = Eodhd::Logger.new

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

      processor = Eodhd::Processor.new(log: log, cfg: cfg, api: api, io: io)

      exchanges_json = processor.fetch_exchanges_list
      exchange_codes = processor.exchange_codes_from(exchanges_json)
      processor.fetch_symbols_for_exchanges(exchange_codes: exchange_codes)
      processor.fetch_eod
    end
  end
end
