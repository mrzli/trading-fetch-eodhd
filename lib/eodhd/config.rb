# frozen_string_literal: true

module Eodhd
  module Config
    class Error < StandardError; end

    Eodhd = Data.define(
      :base_url,
      :api_token,
      :output_dir,
      :request_pause_ms,
      :min_file_age_minutes
    )

    class << self
      def eodhd!
        Eodhd.new(
          base_url: eodhd_base_url!,
          api_token: eodhd_api_token!,
          output_dir: eodhd_output_dir!,
          request_pause_ms: request_pause_ms!,
          min_file_age_minutes: min_file_age_minutes!
        )
      end

      private

      # Read a required env var and return a stripped string.
      def required_env!(key)
        Validate.required_string!(key, ENV[key])
      rescue ArgumentError
        raise Error, "Missing #{key} in environment (.env)"
      end

      def eodhd_api_token!
        required_env!("API_TOKEN")
      end

      def eodhd_output_dir!
        File.expand_path(required_env!("OUTPUT_DIR"))
      end

      def eodhd_base_url!
        base = required_env!("BASE_URL")
        base = base.chomp("/")
        unless base.start_with?("http://", "https://")
          raise Error, "BASE_URL must start with http:// or https://"
        end
        base
      end

      def request_pause_ms!
        raw = ENV.fetch("REQUEST_PAUSE_MS", "100")
        ms = Integer(raw, 10)
        if ms.negative?
          raise Error, "REQUEST_PAUSE_MS must be a non-negative integer."
        end
        ms
      rescue ArgumentError
        raise Error, "REQUEST_PAUSE_MS must be a non-negative integer."
      end

      def min_file_age_minutes!
        raw = ENV.fetch("MIN_FILE_AGE_MINUTES", "60")
        minutes = Integer(raw, 10)
        if minutes.negative?
          raise Error, "MIN_FILE_AGE_MINUTES must be a non-negative integer."
        end
        minutes
      rescue ArgumentError
        raise Error, "MIN_FILE_AGE_MINUTES must be a non-negative integer."
      end
    end
  end
end
