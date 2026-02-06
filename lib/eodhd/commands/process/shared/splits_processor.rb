# frozen_string_literal: true

module Eodhd
  module Commands
    class SplitsProcessor
      class << self
        # Converts splits (with date and factor) to timestamp-based segments with cumulative factors.
        #
        # Input: array of Split objects with .date (Date) and .factor (Numeric - Float or Integer)
        # Output: array of {timestamp: Integer, factor: Float} hashes
        #
        # Each segment represents the cumulative split factor to apply for data
        # strictly before that timestamp. The factor is the product of all splits
        # from that point forward.
        def process(splits)
          return [] if splits.nil? || splits.empty?

          # Splits are sorted by date (ascending)
          # We need to build segments with cumulative factors
          # Segment i has timestamp of split i and cumulative factor of all splits after it
        
          segments = []
          n = splits.length

          (0...n).each do |i|
            split = splits[i]
            timestamp = split.date.to_time.to_i
          
            # Calculate cumulative factor: product of all splits from i to end
            factor = 1.0
            (i...n).each do |j|
              factor *= Float(splits[j].factor)
            end

            segments << { timestamp: timestamp, factor: factor }
          end

          segments
        end
      end
    end
  end
end
