# frozen_string_literal: true

module Logging
  module Shared
    module_function

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

    def default_formatter
      @default_formatter ||= lambda do |severity, datetime, _progname, msg|
        time = datetime.utc.iso8601
        severity = severity.to_s.ljust(5)
        message = msg.is_a?(String) ? msg : msg.inspect
        "#{time} #{severity} #{message}\n"
      end
    end
  end
end
