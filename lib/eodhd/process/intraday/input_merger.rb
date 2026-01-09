# frozen_string_literal: true

module Eodhd
  class InputMerger
    class << self
      def merge(list)
        merged = []
        Array(list).each do |rows|
          next if rows.nil? || rows.empty?

          if merged.empty?
            merged = rows.dup
            next
          end

          merge_in_place(merged, rows)
        end
        merged
      end

      private

      def merge_in_place(merged_rows, next_rows)
        return merged_rows.concat(next_rows) if merged_rows.empty?
        return if next_rows.empty?

        next_first = next_rows.first.fetch(:timestamp)
        merged_last = merged_rows.last.fetch(:timestamp)

        if next_first > merged_last
          merged_rows.concat(next_rows)
          return
        end

        idx = lower_bound_timestamp(merged_rows, next_first)
        merged_rows.slice!(idx, merged_rows.length - idx)
        merged_rows.concat(next_rows)
      end

      def lower_bound_timestamp(rows, timestamp)
        lo = 0
        hi = rows.length

        while lo < hi
          mid = (lo + hi) / 2
          if rows[mid][:timestamp] < timestamp
            lo = mid + 1
          else
            hi = mid
          end
        end

        lo
      end
    end
  end
end
