# frozen_string_literal: true

require "net/http"
require "uri"

require_relative "../../util"

module Eodhd
  class Api
    DEFAULT_MAX_RETRIES = 3
    DEFAULT_BASE_DELAY = 1.0

    def initialize(
      log:,
      base_url:,
      api_token:,
      max_retries: DEFAULT_MAX_RETRIES,
      base_delay: DEFAULT_BASE_DELAY
    )
      @log = log
      @base_url = Validate.http_url("base_url", base_url)
      @api_token = Validate.required_string("api_token", api_token)
      @max_retries = max_retries
      @base_delay = base_delay
    end

    def get_exchanges_list_json
      uri = get_full_url("exchanges-list")
      uri.query = URI.encode_www_form(
        api_token: @api_token,
        fmt: "json"
      )

      retry_with_exponential_backoff do
        response = Net::HTTP.get_response(uri)
        validate_response(response)
        response.body.to_s
      end
    end

    def get_exchange_symbol_list_json(exchange)
      exchange = Validate.required_string("exchange", exchange)

      uri = get_full_url("exchange-symbol-list/#{exchange}")
      uri.query = URI.encode_www_form(
        api_token: @api_token,
        fmt: "json"
      )

      retry_with_exponential_backoff do
        response = Net::HTTP.get_response(uri)
        validate_response(response)
        response.body.to_s
      end
    end

    def get_eod_data_csv(exchange, symbol)
      exchange = Validate.required_string("exchange", exchange)
      symbol = Validate.required_string("symbol", symbol)

      uri = get_full_url("eod/#{symbol}.#{exchange}")
      uri.query = URI.encode_www_form(
        api_token: @api_token,
        fmt: "csv"
      )

      retry_with_exponential_backoff do
        response = Net::HTTP.get_response(uri)
        validate_response(response)
        response.body.to_s
      end
    end

    def get_intraday_csv(exchange, symbol, from:, to:)
      exchange = Validate.required_string("exchange", exchange)
      symbol = Validate.required_string("symbol", symbol)
      from = Validate.integer("from", from)
      to = Validate.integer("to", to)

      uri = get_full_url("intraday/#{symbol}.#{exchange}")
      uri.query = URI.encode_www_form(
        api_token: @api_token,
        fmt: "csv",
        interval: '1m',
        from: from,
        to: to
      )

      retry_with_exponential_backoff do
        response = Net::HTTP.get_response(uri)
        validate_response(response)
        response.body.to_s
      end
    end

    def get_splits_json(exchange, symbol)
      exchange = Validate.required_string("exchange", exchange)
      symbol = Validate.required_string("symbol", symbol)

      uri = get_full_url("splits/#{symbol}.#{exchange}")
      uri.query = URI.encode_www_form(
        api_token: @api_token,
        fmt: "json"
      )

      retry_with_exponential_backoff do
        response = Net::HTTP.get_response(uri)
        validate_response(response)
        response.body.to_s
      end
    end

    def get_dividends_json(exchange, symbol)
      exchange = Validate.required_string("exchange", exchange)
      symbol = Validate.required_string("symbol", symbol)

      uri = get_full_url("div/#{symbol}.#{exchange}")
      uri.query = URI.encode_www_form(
        api_token: @api_token,
        fmt: "json"
      )

      retry_with_exponential_backoff do
        response = Net::HTTP.get_response(uri)
        validate_response(response)
        response.body.to_s
      end
    end

    private

    def get_full_url(path)
      URI.join(@base_url + "/", path)
    end

    def retry_with_exponential_backoff
      attempt = 0
      begin
        attempt += 1
        yield
      rescue StandardError => e
        @log.warn("Request failed (attempt #{attempt}/#{@max_retries + 1}): #{e.class}: #{e.message}")
        if attempt <= @max_retries
          delay = @base_delay * (2 ** (attempt - 1))
          sleep(delay)
          retry
        else
          @log.error("Max retries reached (#{@max_retries}). Giving up.")
          raise
        end
      end
    end

    def validate_response(response)
      unless response.is_a?(Net::HTTPSuccess)
        body_preview = response.body.to_s[0, 500]
        raise "Request failed: HTTP #{response.code} #{response.message}\n#{body_preview}"
      end
    end
  end
end
