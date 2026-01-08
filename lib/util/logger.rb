# frozen_string_literal: true

require "logger"
require "time"

module Eodhd
  class Logger
    def initialize(io: $stdout, level: ENV["LOG_LEVEL"], progname: "eodhd")
      @logger = ::Logger.new(io)
      @logger.level = normalize_level(level)
      @logger.progname = progname
      @logger.formatter = method(:format)
    end

    attr_reader :logger

    def debug(message = nil, &block)
      @logger.debug(message, &block)
    end

    def info(message = nil, &block)
      @logger.info(message, &block)
    end

    def warn(message = nil, &block)
      @logger.warn(message, &block)
    end

    def error(message = nil, &block)
      @logger.error(message, &block)
    end

    private

    def normalize_level(level)
      return ::Logger::INFO if level.nil?

      case level.to_s.strip.downcase
      when "debug" then ::Logger::DEBUG
      when "info" then ::Logger::INFO
      when "warn", "warning" then ::Logger::WARN
      when "error" then ::Logger::ERROR
      when "fatal" then ::Logger::FATAL
      else
        ::Logger::INFO
      end
    end

    def format(severity, datetime, progname, msg)
      time = datetime.utc.iso8601
      severity = severity.to_s.ljust(5)
      message = msg.is_a?(String) ? msg : msg.inspect
      "#{time} #{severity} #{progname}: #{message}\n"
    end
  end

  class NullLogger
    def debug(message = nil, &block); end

    def info(message = nil, &block); end

    def warn(message = nil, &block); end

    def error(message = nil, &block); end
  end
end
