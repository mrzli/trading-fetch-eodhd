# frozen_string_literal: true

module Logging
  class NullLogger
    def debug(message, &block); end

    def info(message, &block); end

    def warn(message, &block); end

    def error(message, &block); end
  end
end
