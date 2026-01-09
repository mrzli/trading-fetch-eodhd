# frozen_string_literal: true

module Eodhd
  class PriceAdjust
    class << self
      def apply(rows, splits = [])
        return rows if splits.empty?

        idx = 0

        rows.map do |row|
          ts = row.fetch(:timestamp)

          while idx < splits.length && ts >= splits[idx][:timestamp]
            idx += 1
          end

          if idx >= splits.length
            row
          else
            factor = splits[idx][:factor]

            row.merge(
              open: adjust_price_for_split(row[:open], factor),
              high: adjust_price_for_split(row[:high], factor),
              low: adjust_price_for_split(row[:low], factor),
              close: adjust_price_for_split(row[:close], factor),
              volume: adjust_volume_for_split(row[:volume], factor)
            )
          end
        end
      end

      private

      def adjust_price_for_split(value, factor)
        value / factor
      end

      def adjust_volume_for_split(value, factor)
        (value * factor).to_i
      end
    end
  end
end
