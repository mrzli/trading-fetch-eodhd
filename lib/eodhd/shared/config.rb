# frozen_string_literal: true

require_relative "../../util"

module Eodhd
  module Config
    class Error < StandardError; end

    Eodhd = Data.define(
      :base_url,
      :api_token,
      :output_dir,
      :request_pause_ms,
      :too_many_requests_pause_ms,
      :min_file_age_minutes,
      :log_level
    )

    class << self
      def eodhd
        Eodhd.new(
          base_url: eodhd_base_url,
          api_token: eodhd_api_token,
          output_dir: eodhd_output_dir,
          request_pause_ms: request_pause_ms,
          too_many_requests_pause_ms: too_many_requests_pause_ms,
          min_file_age_minutes: min_file_age_minutes,
          log_level: log_level
        )
      end

      private

      # Read a required env var and return a stripped string.
      def required_env(key)
        Validate.required_string(key, ENV[key])
      rescue ArgumentError
        raise Error, "Missing #{key} in environment (.env)"
      end

      def eodhd_api_token
        required_env("API_TOKEN")
      end

      def eodhd_output_dir
        File.expand_path(required_env("OUTPUT_DIR"))
      end

      def eodhd_base_url
        base = required_env("BASE_URL")
        base = base.chomp("/")
        unless base.start_with?("http://", "https://")
          raise Error, "BASE_URL must start with http:// or https://"
        end
        base
      end

      def request_pause_ms
        Validate.integer_non_negative("REQUEST_PAUSE_MS", ENV.fetch("REQUEST_PAUSE_MS", "100"))
      rescue ArgumentError
        raise Error, "REQUEST_PAUSE_MS must be a non-negative integer."
      end

      def too_many_requests_pause_ms
        Validate.integer_non_negative("TOO_MANY_REQUESTS_PAUSE", ENV.fetch("TOO_MANY_REQUESTS_PAUSE", "60000"))
      rescue ArgumentError
        raise Error, "TOO_MANY_REQUESTS_PAUSE must be a non-negative integer."
      end

      def min_file_age_minutes
        Validate.integer_non_negative("MIN_FILE_AGE_MINUTES", ENV.fetch("MIN_FILE_AGE_MINUTES", "60"))
      rescue ArgumentError
        raise Error, "MIN_FILE_AGE_MINUTES must be a non-negative integer."
      end

      def log_level
        level = ENV.fetch("LOG_LEVEL", "info").to_s.strip
        level.empty? ? "info" : level
      end
    end
  end
end
