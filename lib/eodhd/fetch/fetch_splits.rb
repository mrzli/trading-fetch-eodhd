# frozen_string_literal: true

require_relative "../../util"
require_relative "../shared/path"
require_relative "shared"

module Eodhd
  class FetchSplits < FetchShared

    def fetch(symbol_entries)
      symbol_entries.each do |entry|
        next unless should_fetch?(entry)
        fetch_single(entry)
      end
    end

    private

    def fetch_single(symbol_entry)
      exchange = Validate.required_string("exchange", symbol_entry[:exchange])
      symbol = Validate.required_string("symbol", symbol_entry[:symbol])
      symbol_with_exchange = "#{symbol}.#{exchange}"

      splits_path = Path.splits(exchange, symbol)
      unless file_stale?(splits_path)
        @log.info("Skipping splits (fresh): #{splits_path}")
        return
      end

      begin
        @log.info("Fetching splits JSON: #{symbol_with_exchange}...")
        splits = @api.get_splits_json(exchange, symbol)
        saved_path = @io.save_json(splits_path, splits, true)
        @log.info("Wrote #{saved_path}")
      rescue StandardError => e
        @log.warn("Failed splits for #{symbol_with_exchange}: #{e.class}: #{e.message}")
      ensure
        pause_between_requests
      end
    end

  end
end
