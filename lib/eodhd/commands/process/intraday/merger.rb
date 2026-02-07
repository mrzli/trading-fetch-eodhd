# frozen_string_literal: true

require_relative "../../../../util"

module Eodhd
  module Commands
    module Process
      module Intraday
        class Merger
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

          idx = Util::BinarySearch.lower_bound(merged_rows, next_first) { |row| row[:timestamp] }
          merged_rows.slice!(idx, merged_rows.length - idx)
          merged_rows.concat(next_rows)
        end
          end
        end
      end
    end
  end
end
