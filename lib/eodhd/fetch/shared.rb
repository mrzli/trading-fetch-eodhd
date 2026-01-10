# frozen_string_literal: true

require "set"

require_relative "../../util"

module Eodhd
  class FetchShared
    SYMBOL_INCLUDED_EXCHANGES = Set.new(["US"]).freeze
    SYMBOL_INCLUDED_REAL_EXCHANGES = Set.new(["NYSE", "NASDAQ"]).freeze
    SYMBOL_INCLUDED_TYPES = Set.new(["common-stock"]).freeze

    def initialize(cfg:, io:)
      @cfg = cfg
      @io = io
    end

    def should_fetch?(symbol_entry)
      return false unless SYMBOL_INCLUDED_EXCHANGES.include?(symbol_entry[:exchange])
      return false unless SYMBOL_INCLUDED_REAL_EXCHANGES.include?(symbol_entry[:real_exchange])
      return false unless SYMBOL_INCLUDED_TYPES.include?(symbol_entry[:type])

      true
    end

    def pause_between_requests
      # return unless @cfg.request_pause_ms.positive?
      # sleep(@cfg.request_pause_ms / 1000.0)
    end

    def file_stale?(relative_path)
      last_updated_at = @io.file_last_updated_at(relative_path)
      return true if last_updated_at.nil?

      min_age_seconds = @cfg.min_file_age_minutes.to_i * 60
      (Time.now - last_updated_at) >= min_age_seconds
    end
  end
end
