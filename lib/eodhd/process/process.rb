# frozen_string_literal: true

require "json"

module Eodhd
  module Process
    module_function

    def run!
      log = Logger.new

      begin
        cfg = Config.eodhd!
      rescue Config::Error => e
        abort e.message
      end

      io = Io.new(output_dir: cfg.output_dir)

      strategy = ProcessStrategy.new(log: log, cfg: cfg, io: io)
      strategy.process_eod!
      strategy.process_intraday!
    end
  end
end
