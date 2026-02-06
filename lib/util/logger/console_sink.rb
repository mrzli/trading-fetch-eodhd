# frozen_string_literal: true

require "logger"

require_relative "shared"

module Util
  module Logger
    class ConsoleSink
      def initialize(level:, progname: "eodhd", formatter: nil)
        level = Util::Logger::Shared.normalize_level(level)
        formatter ||= Util::Logger::Shared.default_formatter

        @logger = ::Logger.new($stdout)
        @logger.level = level
        @logger.progname = progname
        @logger.formatter = formatter
      end

      def debug(message, &block)
        @logger.debug(message, &block)
      end

      def info(message, &block)
        @logger.info(message, &block)
      end

      def warn(message, &block)
        @logger.warn(message, &block)
      end

      def error(message, &block)
        @logger.error(message, &block)
      end
    end
  end
end
