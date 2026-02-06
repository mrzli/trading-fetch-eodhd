# frozen_string_literal: true

require_relative "../../util"

module Eodhd
  module Config
    class Error < StandardError; end

    Eodhd = Data.define(
      :log_level,
      :base_url,
      :api_token,
      :output_dir,
      :min_file_age_minutes,
      :default_workers,
      :too_many_requests_pause_ms
    )

    class << self
      def eodhd
        Eodhd.new(
          log_level: log_level,
          base_url: base_url,
          api_token: api_token,
          output_dir: output_dir,
          min_file_age_minutes: min_file_age_minutes,
          default_workers: default_workers,
          too_many_requests_pause_ms: too_many_requests_pause_ms
        )
      end

      private

      def log_level
        level = ENV.fetch("LOG_LEVEL", "info").to_s.strip
        level.empty? ? "info" : level
      end

      def base_url
        base = required_env("BASE_URL")
        base = base.chomp("/")
        unless base.start_with?("http://", "https://")
          raise Error, "BASE_URL must start with http:// or https://"
        end
        base
      end

      def api_token
        required_env("API_TOKEN")
      end

      def too_many_requests_pause_ms
        Util::Validate.integer_non_negative("TOO_MANY_REQUESTS_PAUSE", ENV.fetch("TOO_MANY_REQUESTS_PAUSE", "60000"))
      rescue ArgumentError
        raise Error, "TOO_MANY_REQUESTS_PAUSE must be a non-negative integer."
      end

      def default_workers
        Util::Validate.integer_positive("DEFAULT_WORKERS", ENV.fetch("DEFAULT_WORKERS", "4"))
      rescue ArgumentError
        raise Error, "DEFAULT_WORKERS must be a positive integer."
      end

      def output_dir
        File.expand_path(required_env("OUTPUT_DIR"))
      end

      def min_file_age_minutes
        Util::Validate.integer_non_negative("MIN_FILE_AGE_MINUTES", ENV.fetch("MIN_FILE_AGE_MINUTES", "60"))
      rescue ArgumentError
        raise Error, "MIN_FILE_AGE_MINUTES must be a non-negative integer."
      end

      # Read a required env var and return a stripped string.
      def required_env(key)
        Util::Validate.required_string(key, ENV[key])
      rescue ArgumentError
        raise Error, "Missing #{key} in environment (.env)"
      end
    end
  end
end
