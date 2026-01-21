# frozen_string_literal: true

require_relative "config"
require_relative "io"
require_relative "api"
require_relative "../../util"

module Eodhd
  class Container
    attr_reader :config, :logger, :api, :io

    def initialize(command: "fetch")
      @command = command
      @config = load_config
      @logger = build_logger
      @api = build_api
      @io = build_io
    end

    private

    def load_config
      Config.eodhd
    rescue Config::Error => e
      abort e.message
    end

    def build_logger
      sinks = [
        ConsoleSink.new(
          level: @config.log_level,
          progname: @command
        ),
        FileSink.new(
          command: @command,
          output_dir: @config.output_dir,
          level: @config.log_level,
          progname: @command
        )
      ]
      Logger.new(sinks: sinks)
    end

    def build_api
      Api.new(
        cfg: @config,
        log: @logger
      )
    end

    def build_io
      Io.new(output_dir: @config.output_dir)
    end
  end
end
