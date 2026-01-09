# frozen_string_literal: true

module Eodhd
  class PriceAdjust
    class << self
      def apply(rows, splits, dividends)
        return rows if splits.empty? && dividends.empty?

        splits_idx = 0

        rows.map do |row|
          ts = row.fetch(:timestamp)

          while splits_idx < splits.length && ts >= splits[splits_idx][:timestamp]
            splits_idx += 1
          end

          if splits_idx >= splits.length
            row
          else
            factor = splits[splits_idx][:factor]

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
