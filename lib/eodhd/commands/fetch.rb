# frozen_string_literal: true

require "json"

require_relative "../../util"
require_relative "../fetch/fetch_strategy"
require_relative "../shared/config"
require_relative "../shared/api"
require_relative "../shared/io"

module Eodhd
  module Fetch
    module_function

    def run
      log = Logger.new

      begin
        cfg = Config.eodhd
      rescue Config::Error => e
        abort e.message
      end

      api = Api.new(
        base_url: cfg.base_url,
        api_token: cfg.api_token
      )

      io = Io.new(output_dir: cfg.output_dir)

      strategy = FetchStrategy.new(log: log, cfg: cfg, api: api, io: io)
      strategy.run
    end
  end
end
