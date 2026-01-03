# frozen_string_literal: true

module Eodhd
  class DateUtil
    class << self
      # Formats unix epoch seconds as UTC "YYYY-MM-DD_HH-MM-SS".
      def utc_compact_datetime(value)
        seconds = Validate.integer!("seconds", value)
        Time.at(seconds).utc.strftime("%Y-%m-%d_%H-%M-%S")
      end
    end
  end
end
