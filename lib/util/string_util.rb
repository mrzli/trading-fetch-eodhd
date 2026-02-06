# frozen_string_literal: true

module Util
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

      def truncate_middle(str, max_length = 80)
        return str if str.length <= max_length

        # Reserve 3 chars for "..."
        available = max_length - 3
        # Split available space, preferring to show more at the end
        start_length = available / 2
        end_length = available - start_length

        "#{str[0...start_length]}...#{str[-end_length..]}"
      end
    end
  end
end
