# frozen_string_literal: true

require "logger"

require_relative "shared"

module Logging
  class ConsoleSink
    def initialize(level:, formatter: nil)
      level = Shared.normalize_level(level)
      formatter ||= Shared.default_formatter

      @logger = ::Logger.new($stdout)
      @logger.level = level
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
