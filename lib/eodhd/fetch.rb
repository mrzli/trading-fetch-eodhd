# frozen_string_literal: true

require "json"

module Eodhd
  module Fetch
    module_function

    def run!
      log = Logger.new

      begin
        cfg = Config.eodhd!
      rescue Config::Error => e
        abort e.message
      end

      api = Api.new(
        base_url: cfg.base_url,
        api_token: cfg.api_token
      )

      io = Io.new(output_dir: cfg.output_dir)

      processor = Processor.new(log: log, cfg: cfg, api: api, io: io)

      exchanges_json = processor.fetch_exchanges_list
      exchange_codes = ExchangesListParser.exchange_codes_from_json(exchanges_json, log)
      processor.fetch_symbols_for_exchanges(exchange_codes)
      processor.fetch_eod
    end
  end
end
