# frozen_string_literal: true

module Eodhd
  module Commands
    module Fetch
      module Subcommands
        module Intraday
          class Merger
            class << self
              # Merges new rows into existing rows, replacing any overlapping rows
              # All inputs are assumed to be sorted by timestamp
              # @param existing_rows [Array<Hash>] Existing sorted rows, or nil
              # @param new_rows [Array<Hash>] New sorted rows to merge in
              # @return [Array<Hash>] Merged and sorted rows
              def merge(existing_rows, new_rows)
                return new_rows if existing_rows.nil? || existing_rows.empty?
                return existing_rows if new_rows.nil? || new_rows.empty?

                exclude_start_ts = new_rows.first[:timestamp]
                exclude_end_ts = new_rows.last[:timestamp]

                rows_before, rows_after = split_around_range(existing_rows, exclude_start_ts, exclude_end_ts)
                rows_before + new_rows + rows_after
              end

              private

              # Splits rows into two parts: before and after the excluded range
              # @param rows [Array<Hash>] Sorted rows
              # @param exclude_start_ts [Integer] Start of range to exclude (inclusive)
              # @param exclude_end_ts [Integer] End of range to exclude (inclusive)
              # @return [Array<Array<Hash>>] Two arrays: [rows_before, rows_after]
              def split_around_range(rows, exclude_start_ts, exclude_end_ts)
                return [[], []] if rows.empty?

                # Find first row >= exclude_start_ts
                start_idx = Util::BinarySearch.lower_bound(rows, exclude_start_ts) { |row| row[:timestamp] }

                # Find first row > exclude_end_ts
                end_idx = Util::BinarySearch.upper_bound(rows, exclude_end_ts) { |row| row[:timestamp] }

                rows_before = start_idx > 0 ? rows[0...start_idx] : []
                rows_after = end_idx < rows.length ? rows[end_idx..-1] : []

                [rows_before, rows_after]
              end
            end
          end
        end
      end
    end
  end
end
