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
      processor.fetch!
    end
  end
end
