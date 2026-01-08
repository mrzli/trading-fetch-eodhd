# frozen_string_literal: true

require_relative "./validate"

module Eodhd
  class DateUtil
    class << self
      # Formats unix epoch seconds as UTC "YYYY-MM-DD_HH-MM-SS".
      def seconds_to_datetime(value)
        seconds = Validate.integer!("seconds", value)
        Time.at(seconds).utc.strftime("%Y-%m-%d_%H-%M-%S")
      end

      # Parses UTC "YYYY-MM-DD_HH-MM-SS" into unix epoch seconds.
      def datetime_to_seconds(value)
        str = Validate.required_string!("datetime", value)
        Time.strptime("#{str} +0000", "%Y-%m-%d_%H-%M-%S %z").to_i
      rescue ArgumentError
        raise ArgumentError, "datetime must be in format YYYY-MM-DD_HH-MM-SS"
      end
    end
  end
end
