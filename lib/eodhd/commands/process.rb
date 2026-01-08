# frozen_string_literal: true

require "json"

require_relative "../../util"
require_relative "../process/process_strategy"
require_relative "../shared/config"
require_relative "../shared/io"

module Eodhd
  module Process
    module_function

    def run!(mode: "eod")
      log = Logger.new

      begin
        cfg = Config.eodhd!
      rescue Config::Error => e
        abort e.message
      end

      io = Io.new(output_dir: cfg.output_dir)

      strategy = ProcessStrategy.new(log: log, cfg: cfg, io: io)

      mode = mode.to_s.strip.downcase
      case mode
      when "eod"
        strategy.process_eod!
      when "intraday"
        strategy.process_intraday!
      else
        raise ArgumentError, "Unknown mode: #{mode.inspect}. Expected 'eod' or 'intraday'."
      end
    end
  end
end
