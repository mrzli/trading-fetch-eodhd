# frozen_string_literal: true

module Eodhd
  module Validate
    module_function

    # Returns a stripped string, or raises if missing/blank.
    def required_string!(name, value)
      str = value.to_s.strip
      raise ArgumentError, "#{name} is required" if str.empty?
      str
    end

    # Validates and normalizes an HTTP(S) base URL.
    # - Requires http:// or https://
    # - Strips trailing slash
    def http_url!(name, value)
      str = required_string!(name, value).chomp("/")
      unless str.start_with?("http://", "https://")
        raise ArgumentError, "#{name} must start with http:// or https://"
      end
      str
    end
  end
end
