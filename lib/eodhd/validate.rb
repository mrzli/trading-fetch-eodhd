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
  end
end
