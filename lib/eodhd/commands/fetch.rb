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
      begin
        cfg = Config.eodhd
      rescue Config::Error => e
        abort e.message
      end

      sinks = [
        Eodhd::ConsoleSink.new(
          level: cfg.log_level,
          progname: "fetch"
        ),
        Eodhd::FileSink.new(
          command: "fetch",
          output_dir: cfg.output_dir,
          level: cfg.log_level,
          progname: "fetch"
        )
      ]

      log = Eodhd::Logger.new(sinks: sinks)

      api = Api.new(
        log: log,
        base_url: cfg.base_url,
        api_token: cfg.api_token,
        too_many_requests_pause_ms: cfg.too_many_requests_pause_ms
      )

      io = Io.new(output_dir: cfg.output_dir)

      strategy = FetchStrategy.new(log: log, cfg: cfg, api: api, io: io)
      strategy.run
    end
  end
end
