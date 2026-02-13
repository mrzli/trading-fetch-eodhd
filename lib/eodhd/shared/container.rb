# frozen_string_literal: true

module Eodhd
  module Shared
    class Container
      attr_reader :config, :logger, :api, :io, :data_reader

      def initialize(command: "fetch")
        @command = command
        @config = load_config
        @logger = build_logger
        @api = build_api
        @io = build_io
        @data_reader = build_data_reader
      end

      private

      def load_config
        Config.eodhd
      rescue Config::Error => e
        abort e.message
      end

      def build_logger
        sinks = [
          Logging::ConsoleSink.new(
            level: @config.log_level
          ),
          Logging::FileSink.new(
            command: @command,
            output_dir: @config.output_dir,
            level: @config.log_level
          )
        ]
        Logging::Logger.new(sinks: sinks)
      end

      def build_api
        ::Eodhd::Shared::Api.new(
          cfg: @config,
          log: @logger
        )
      end

      def build_io
        ::Eodhd::Shared::Io.new(output_dir: @config.output_dir)
      end

      def build_data_reader
        ::Eodhd::Shared::DataReader.new(io: @io)
      end
    end
  end
end
