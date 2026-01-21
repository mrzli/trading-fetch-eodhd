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
        ConsoleSink.new(
          level: cfg.log_level,
          progname: "fetch"
        ),
        FileSink.new(
          command: "fetch",
          output_dir: cfg.output_dir,
          level: cfg.log_level,
          progname: "fetch"
        )
      ]

      log = Logger.new(sinks: sinks)

      api = Api.new(
        cfg: cfg,
        log: log
      )

      io = Io.new(output_dir: cfg.output_dir)

      strategy = FetchStrategy.new(log: log, cfg: cfg, api: api, io: io)
      strategy.run
    end
  end
end
