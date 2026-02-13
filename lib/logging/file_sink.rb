# frozen_string_literal: true

require "logger"
require "fileutils"

require_relative "shared"

module Logging
  class FileSink
    def initialize(command:, output_dir:, level:, formatter: nil)
      level = Shared.normalize_level(level)
      formatter ||= Shared.default_formatter

      now = Time.now
      log_dir = File.join(output_dir, "log")
      FileUtils.mkdir_p(log_dir)

      date = now.strftime("%Y-%m-%d")
      log_file = File.join(log_dir, "#{date}_#{command}.log")

      @logger = ::Logger.new(log_file)
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
