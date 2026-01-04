# frozen_string_literal: true

require "json"
require "set"
require "time"

module Eodhd
  class ProcessStrategy
    def initialize(log:, cfg:, io:)
      @log = log
      @cfg = cfg
      @io = io
    end

    def run!
      puts "Processing not yet implemented."
    end

    private
  end
end
