# frozen_string_literal: true

require "net/http"
require "uri"

module Eodhd
  class Api
    def initialize(base_url:, api_token:)
      @base_url = Validate.http_url!("base_url", base_url)
      @api_token = Validate.required_string!("api_token", api_token)
    end

    def get_exchanges_list_json!
      uri = get_full_url("exchanges-list")
      uri.query = URI.encode_www_form(
        api_token: @api_token,
        fmt: "json"
      )

      response = Net::HTTP.get_response(uri)
      validate_response!(response)

      response.body.to_s
    end

    def get_exchange_symbol_list_json!(exchange_code)
      exchange_code = Validate.required_string!("exchange_code", exchange_code)

      uri = get_full_url("exchange-symbol-list/#{exchange_code}")
      uri.query = URI.encode_www_form(
        api_token: @api_token,
        fmt: "json"
      )

      response = Net::HTTP.get_response(uri)
      validate_response!(response)

      response.body.to_s
    end

    def get_eod_data_csv!(exchange, symbol)
      exchange = Validate.required_string!("exchange", exchange)
      symbol = Validate.required_string!("symbol", symbol)

      uri = get_full_url("eod/#{symbol}.#{exchange}")
      uri.query = URI.encode_www_form(
        api_token: @api_token,
        fmt: "csv"
      )

      response = Net::HTTP.get_response(uri)
      validate_response!(response)

      response.body.to_s
    end

    def get_intraday_csv!(exchange, symbol, from:, to:)
      exchange = Validate.required_string!("exchange", exchange)
      symbol = Validate.required_string!("symbol", symbol)
      from = Validate.integer!("from", from)
      to = Validate.integer!("to", to)

      uri = get_full_url("intraday/#{symbol}.#{exchange}")
      uri.query = URI.encode_www_form(
        api_token: @api_token,
        fmt: "csv",
        interval: '1m',
        from: from,
        to: to
      )

      response = Net::HTTP.get_response(uri)
      validate_response!(response)

      response.body.to_s
    end

    def get_splits_json!(exchange, symbol)
      exchange = Validate.required_string!("exchange", exchange)
      symbol = Validate.required_string!("symbol", symbol)

      uri = get_full_url("splits/#{symbol}.#{exchange}")
      uri.query = URI.encode_www_form(
        api_token: @api_token,
        fmt: "json"
      )

      response = Net::HTTP.get_response(uri)
      validate_response!(response)

      response.body.to_s
    end

    private

    def get_full_url(path)
      URI.join(@base_url + "/", path)
    end

    def validate_response!(response)
      unless response.is_a?(Net::HTTPSuccess)
        body_preview = response.body.to_s[0, 500]
        raise "Request failed: HTTP #{response.code} #{response.message}\n#{body_preview}"
      end
    end
  end
end
