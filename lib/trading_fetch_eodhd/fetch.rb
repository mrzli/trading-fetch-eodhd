# frozen_string_literal: true

require "fileutils"
require "net/http"
require "uri"

module TradingFetchEodhd
  module Fetch
    module_function

    def fetch_mcd_csv!(api_token:, base_url:, output_dir:)
      api_token = Validate.required_string!("api_token", api_token)
      base_url = Validate.required_string!("base_url", base_url)
      output_dir = Validate.required_string!("output_dir", output_dir)

      uri = URI.join(base_url.end_with?("/") ? base_url : (base_url + "/"), "eod/MCD.US")
      uri.query = URI.encode_www_form(
        api_token: api_token,
        fmt: "csv"
      )

      response = Net::HTTP.get_response(uri)

      unless response.is_a?(Net::HTTPSuccess)
        body_preview = response.body.to_s[0, 500]
        raise "Request failed: HTTP #{response.code} #{response.message}\n#{body_preview}"
      end

      FileUtils.mkdir_p(output_dir)
      output_path = File.join(output_dir, "MCD.US.csv")
      File.write(output_path, response.body)
      output_path
    end
  end
end
