# frozen_string_literal: true

require "net/http"
require "uri"


module Eodhd
  module Shared
    class Api
      DEFAULT_MAX_RETRIES = 3
      DEFAULT_BASE_DELAY = 1.0

      class TooManyRequestsError < StandardError; end

      def initialize(cfg:, log:)
        @log = log
        @base_url = Util::Validate.http_url("base_url", cfg.base_url)
        @api_token = Util::Validate.required_string("api_token", cfg.api_token)
        @too_many_requests_pause_ms = Util::Validate.integer_non_negative(
          "too_many_requests_pause_ms",
          cfg.too_many_requests_pause_ms
        )
        @max_retries = DEFAULT_MAX_RETRIES
        @base_delay = DEFAULT_BASE_DELAY
      end

      def get_exchanges_list_json
        uri = get_full_url("exchanges-list")
        uri.query = URI.encode_www_form(
          api_token: @api_token,
          fmt: "json"
        )

        response = make_request(uri)
        response.body.to_s
      end

      def get_exchange_symbol_list_json(exchange)
        exchange = Util::Validate.required_string("exchange", exchange)

        uri = get_full_url("exchange-symbol-list/#{exchange}")
        uri.query = URI.encode_www_form(
          api_token: @api_token,
          fmt: "json"
        )

        response = make_request(uri)
        response.body.to_s
      end

      def get_eod_data_csv(exchange, symbol)
        exchange = Validate.required_string("exchange", exchange)
        symbol = Validate.required_string("symbol", symbol)

        uri = get_full_url("eod/#{symbol}.#{exchange}")
        uri.query = URI.encode_www_form(
          api_token: @api_token,
          fmt: "csv"
        )

        response = make_request(uri)
        response.body.to_s
      end

      def get_intraday_csv(exchange, symbol, from:, to:)
        exchange = Util::Validate.required_string("exchange", exchange)
        symbol = Util::Validate.required_string("symbol", symbol)
        from = Util::Validate.integer("from", from)
        to = Util::Validate.integer("to", to)

        uri = get_full_url("intraday/#{symbol}.#{exchange}")
        uri.query = URI.encode_www_form(
          api_token: @api_token,
          fmt: "csv",
          interval: "1m",
          from: from,
          to: to
        )

        response = make_request(uri)
        response.body.to_s
      end

      def get_splits_json(exchange, symbol)
        exchange = Validate.required_string("exchange", exchange)
        symbol = Validate.required_string("symbol", symbol)

        uri = get_full_url("splits/#{symbol}.#{exchange}")
        uri.query = URI.encode_www_form(
          api_token: @api_token,
          fmt: "json"
        )

        response = make_request(uri)
        response.body.to_s
      end

      def get_dividends_json(exchange, symbol)
        exchange = Validate.required_string("exchange", exchange)
        symbol = Validate.required_string("symbol", symbol)

        uri = get_full_url("div/#{symbol}.#{exchange}")
        uri.query = URI.encode_www_form(
          api_token: @api_token,
          fmt: "json"
        )

        response = make_request(uri)
        response.body.to_s
      end

      private

      def get_full_url(path)
        URI.join(@base_url + "/", path)
      end

      def make_request(uri)
        retry_with_exponential_backoff do
          response = Net::HTTP.get_response(uri)
          raise TooManyRequestsError, "HTTP 429 Too Many Requests" if too_many_requests?(response)
          validate_response(response)
          pause_if_rate_limit_low(response)
          response
        end
      end

      def retry_with_exponential_backoff
        attempt = 0
        begin
          attempt += 1
          yield
        rescue TooManyRequestsError => e
          pause_requests!(reason: e.message)
          attempt = 0
          retry
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

      def pause_if_rate_limit_low(response)
        remaining = response["X-RateLimit-Remaining"]
        return if remaining.nil?

        remaining = remaining.to_i
        return if remaining > 50

        pause_requests!(reason: "Low rate limit remaining", remaining: remaining)
      end

      def too_many_requests?(response)
        response.code.to_i == 429
      end

      def pause_requests!(reason:, remaining: nil)
        return unless @too_many_requests_pause_ms.positive?

        pause_seconds = @too_many_requests_pause_ms / 1000.0
        msg = "Pausing requests for #{(@too_many_requests_pause_ms).to_i}ms"
        msg += " (#{reason})" if reason
        msg += " (X-RateLimit-Remaining=#{remaining})" if remaining
        @log.warn(msg)
        sleep(pause_seconds)
      end
    end
  end
end
