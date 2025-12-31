# frozen_string_literal: true

module TradingFetchEodhd
  module Config
    class Error < StandardError; end

    Eodhd = Data.define(:base_url, :api_token, :output_dir)

    module_function

    # Read a required env var and return a stripped string.
    def required_env!(key)
      Validate.required_string!(key, ENV[key])
    rescue ArgumentError
      raise Error, "Missing #{key} in environment (.env)"
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

    def eodhd_base_url!
      base = required_env!("EODHD_BASE_URL")
      base = base.chomp("/")
      unless base.start_with?("http://", "https://")
        raise Error, "EODHD_BASE_URL must start with http:// or https://"
      end
      base
    end

    def eodhd!
      Eodhd.new(
        base_url: eodhd_base_url!,
        api_token: eodhd_api_token!,
        output_dir: eodhd_output_dir!
      )
    end
  end
end
