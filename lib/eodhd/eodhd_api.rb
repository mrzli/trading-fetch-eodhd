# frozen_string_literal: true

require "net/http"
require "uri"

module Eodhd
  class EodhdApi
    def initialize(base_url:, api_token:)
      @base_url = Validate.required_string!("base_url", base_url).chomp("/")
      @api_token = Validate.required_string!("api_token", api_token)

      unless @base_url.start_with?("http://", "https://")
        raise ArgumentError, "base_url must start with http:// or https://"
      end
    end

    # Hardcoded first iteration: fetch CSV for MCD.US
    def fetch_mcd_csv!
      uri = URI.join(@base_url + "/", "eod/MCD.US")
      uri.query = URI.encode_www_form(
        api_token: @api_token,
        fmt: "csv"
      )

      response = Net::HTTP.get_response(uri)

      unless response.is_a?(Net::HTTPSuccess)
        body_preview = response.body.to_s[0, 500]
        raise "Request failed: HTTP #{response.code} #{response.message}\n#{body_preview}"
      end

      response.body.to_s
    end
  end
end
