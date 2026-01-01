# frozen_string_literal: true

require "json"

module Eodhd
  module Fetch
    module_function

    def run!
      log = Eodhd::Logger.new

      begin
        cfg = Eodhd::Config.eodhd!
      rescue Eodhd::Config::Error => e
        abort e.message
      end

      api = Eodhd::Api.new(
        base_url: cfg.base_url,
        api_token: cfg.api_token
      )

      io = Eodhd::Io.new(output_dir: cfg.output_dir)

      exchanges_relative_path = Eodhd::Path.exchanges_list
      exchanges_json = if file_stale?(io: io, relative_path: exchanges_relative_path, min_age_minutes: cfg.min_file_age_minutes)
        log.info("Fetching exchanges list...")
        fetched = api.get_exchanges_list_json!
        exchanges_path = io.save_json!(
          relative_path: exchanges_relative_path,
          json: fetched,
          pretty: true
        )
        log.info("Wrote #{exchanges_path}")
        fetched
      else
        log.info("Skipping exchanges list (fresh): #{exchanges_relative_path}")
        io.read_text(relative_path: exchanges_relative_path)
      end

      exchanges = JSON.parse(exchanges_json)
      unless exchanges.is_a?(Array)
        raise TypeError, "Expected exchanges list JSON to be an Array, got #{exchanges.class}"
      end

      exchange_codes = exchanges.filter_map do |exchange|
        next unless exchange.is_a?(Hash)

        code = exchange["Code"]
        code = code.to_s.strip
        next if code.empty?

        code
      end

      exchange_codes.each do |exchange_code|
        symbols_relative_path = Eodhd::Path.exchange_symbol_list(exchange_code: exchange_code)
        unless file_stale?(io: io, relative_path: symbols_relative_path, min_age_minutes: cfg.min_file_age_minutes)
          log.info("Skipping symbols (fresh): #{symbols_relative_path}")
          next
        end

        begin
          symbols_json = api.get_exchange_symbol_list_json!(exchange_code: exchange_code)
          symbols_path = io.save_json!(
            relative_path: symbols_relative_path,
            json: symbols_json,
            pretty: true
          )
          log.info("Wrote #{symbols_path}")
        rescue StandardError => e
          log.warn("Failed symbols for #{exchange_code}: #{e.class}: #{e.message}")
        ensure
          if cfg.request_pause_ms.positive?
            sleep(cfg.request_pause_ms / 1000.0)
          end
        end
      end

      mcd_relative_path = Eodhd::Path.mcd_csv
      if file_stale?(io: io, relative_path: mcd_relative_path, min_age_minutes: cfg.min_file_age_minutes)
        log.info("Fetching MCD.US CSV...")
        csv = api.fetch_mcd_csv!
        output_path = io.save_mcd_csv!(csv: csv)
        log.info("Wrote #{output_path}")
      else
        log.info("Skipping MCD.US CSV (fresh): #{mcd_relative_path}")
      end
    end
    

    def file_stale?(io:, relative_path:, min_age_minutes:)
      min_age_minutes = Validate.required_string!("min_age_minutes", min_age_minutes).to_i
      last_updated_at = io.file_last_updated_at(relative_path: relative_path)
      return true if last_updated_at.nil?

      (Time.now - last_updated_at) >= (min_age_minutes * 60)
    end

    private :file_stale?
  end
end
