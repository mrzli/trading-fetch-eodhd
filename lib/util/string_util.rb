# frozen_string_literal: true

module Eodhd
  class StringUtil
    class << self
      def kebab_case(value)
        str = value.to_s.strip
        return "" if str.empty?

        # Normalize obvious separators first.
        str = str.tr("_", " ")

        # Split camelCase / PascalCase and acronyms (HTTPServer -> HTTP Server).
        str = str.gsub(/([A-Z]+)([A-Z][a-z])/, "\\1 \\2")
        str = str.gsub(/([a-z\d])([A-Z])/, "\\1 \\2")

        # Replace any remaining non-alphanumerics with spaces.
        str = str.gsub(/[^A-Za-z0-9]+/, " ")

        parts = str.strip.split(/\s+/).reject(&:empty?)
        parts.map!(&:downcase)
        parts.join("-")
      end
    end
  end
end
