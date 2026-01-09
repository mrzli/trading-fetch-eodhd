# frozen_string_literal: true

module Eodhd
  class EodAdjust
    class << self
      def apply(rows, segments)
        segments ||= []
        return rows if segments.empty?

        idx = 0

        rows.map do |row|
          ts = row.fetch(:timestamp)

          while idx < segments.length && ts >= segments[idx][:timestamp]
            idx += 1
          end

          if idx >= segments.length
            row
          else
            factor = segments[idx][:factor]
            if factor == 1 || factor == Rational(1, 1)
              row
            else
              {
                timestamp: ts,
                date: row[:date],
                open: adjust_price(row[:open], factor),
                high: adjust_price(row[:high], factor),
                low: adjust_price(row[:low], factor),
                close: adjust_price(row[:close], factor),
                volume: adjust_volume(row[:volume], factor)
              }
            end
          end
        end
      end

      private

      def adjust_price(value, factor)
        value / factor
      end

      def adjust_volume(value, factor)
        (value * factor).to_i
      end
    end
  end
end
