# frozen_string_literal: true

require "logger"
require "time"

require_relative "shared"

class Eodhd::Logger
  def initialize(sinks:)
    @sinks = Array(sinks)
  end

  def debug(message, &block)
    @sinks.each { |sink| sink.debug(message, &block) }
  end

  def info(message, &block)
    @sinks.each { |sink| sink.info(message, &block) }
  end

  def warn(message, &block)
    @sinks.each { |sink| sink.warn(message, &block) }
  end

  def error(message, &block)
    @sinks.each { |sink| sink.error(message, &block) }
  end
end
