# frozen_string_literal: true

require "json"
require_relative "processor"

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

      processor = Eodhd::Processor.new(log: log, cfg: cfg)

      exchanges_json = processor.fetch_exchanges_list(api: api, io: io)
      exchange_codes = processor.exchange_codes_from(exchanges_json)
      processor.fetch_symbols_for_exchanges(api: api, io: io, exchange_codes: exchange_codes)
      processor.fetch_mcd_csv(api: api, io: io)
    end
  end
end
