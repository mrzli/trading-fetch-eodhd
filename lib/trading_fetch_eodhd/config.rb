# frozen_string_literal: true

module TradingFetchEodhd
  module Config
    class Error < StandardError; end

    module_function

    # Read a required env var and return a stripped string.
    def required_env!(key)
      value = ENV[key].to_s.strip
      raise Error, "Missing #{key} in environment (.env)" if value.empty?
      value
    end

    # Read an optional env var, with default.
    def optional_env(key, default: nil)
      value = ENV[key]
      value.nil? ? default : value.to_s
    end

    def app_name
      optional_env("APP_NAME", default: "(missing APP_NAME)").to_s
    end

    def eodhd_api_token!
      required_env!("EODHD_API_TOKEN")
    end

    def eodhd_output_dir!
      File.expand_path(required_env!("EODHD_OUTPUT_DIR"))
    end
  end
end
