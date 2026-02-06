# frozen_string_literal: true

require "logger"
require "fileutils"

require_relative "shared"

module Logging
  class FileSink
    def initialize(command:, output_dir:, level:, progname: "eodhd", formatter: nil)
      level = Shared.normalize_level(level)
      formatter ||= Shared.default_formatter

      now = Time.now
      date_dir = now.strftime("%Y-%m-%d")
      log_dir = File.join(output_dir, "log", date_dir)
      FileUtils.mkdir_p(log_dir)

      timestamp = now.strftime("%H-%M-%S")
      log_file = File.join(log_dir, "#{command}_#{timestamp}.log")

      @logger = ::Logger.new(log_file)
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
