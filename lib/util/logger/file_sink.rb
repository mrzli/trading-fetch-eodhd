# frozen_string_literal: true

require "logger"
require "fileutils"

require_relative "shared"

class Eodhd::FileSink
  def initialize(command:, output_dir:, level:, progname: "eodhd", formatter: nil)
    level = Eodhd::LoggerShared.normalize_level(level)
    formatter ||= Eodhd::LoggerShared.default_formatter

    log_dir = File.join(output_dir, "log")
    FileUtils.mkdir_p(log_dir)

    timestamp = Time.now.strftime("%Y-%m-%d_%H-%M-%S")
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
