# frozen_string_literal: true

module Eodhd
  module Commands
    class PriceAdjust
      class << self
        def apply(rows, splits, dividends)
          return rows if splits.empty? && dividends.empty?

          splits_idx = 0
          dividends_idx = 0

          rows.map do |row|
            ts = row.fetch(:timestamp)

            while splits_idx < splits.length && ts >= splits[splits_idx][:timestamp]
              splits_idx += 1
            end

            split_factor = splits_idx < splits.length ? splits[splits_idx][:factor] : 1.0
  
            while dividends_idx < dividends.length && ts >= dividends[dividends_idx][:timestamp]
              dividends_idx += 1
            end

            dividend_multiplier = dividends_idx < dividends.length ? dividends[dividends_idx][:multiplier] : 1.0

            if split_factor == 1.0 && dividend_multiplier == 1.0
              row
            else
              adjusted_open = adjust_price_for_split(row[:open], split_factor)
              adjusted_high = adjust_price_for_split(row[:high], split_factor)
              adjusted_low = adjust_price_for_split(row[:low], split_factor)
              adjusted_close = adjust_price_for_split(row[:close], split_factor)
              adjusted_volume = adjust_volume_for_split(row[:volume], split_factor)

              adjusted_open = adjust_price_for_dividend(adjusted_open, dividend_multiplier)
              adjusted_high = adjust_price_for_dividend(adjusted_high, dividend_multiplier)
              adjusted_low = adjust_price_for_dividend(adjusted_low, dividend_multiplier)
              adjusted_close = adjust_price_for_dividend(adjusted_close, dividend_multiplier)

              row.merge(
                open: adjusted_open,
                high: adjusted_high,
                low: adjusted_low,
                close: adjusted_close,
                volume: adjusted_volume
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

        def adjust_price_for_dividend(value, multiplier)
          value * multiplier
        end
      end
    end
  end
end
