# frozen_string_literal: true

require_relative "../../../util"

module Eodhd
  class IntradayCsvMerger
    # Merges new rows into existing rows, replacing any rows in the exclude range
    # All inputs are assumed to be sorted by timestamp
    # @param existing_rows [Array<Hash>] Existing sorted rows, or nil
    # @param new_rows [Array<Hash>] New sorted rows to merge in
    # @param exclude_start_ts [Integer] Start timestamp of range to exclude from existing
    # @param exclude_end_ts [Integer] End timestamp of range to exclude from existing
    # @return [Array<Hash>] Merged and sorted rows
    def self.merge(existing_rows, new_rows, exclude_start_ts, exclude_end_ts)
      return new_rows if existing_rows.nil? || existing_rows.empty?
      return existing_rows if new_rows.nil? || new_rows.empty?

      rows_before, rows_after = split_around_range(existing_rows, exclude_start_ts, exclude_end_ts)
      rows_before + new_rows + rows_after
    end

    # Splits rows into two parts: before and after the excluded range
    # @param rows [Array<Hash>] Sorted rows
    # @param exclude_start_ts [Integer] Start of range to exclude (inclusive)
    # @param exclude_end_ts [Integer] End of range to exclude (inclusive)
    # @return [Array<Array<Hash>>] Two arrays: [rows_before, rows_after]
    def self.split_around_range(rows, exclude_start_ts, exclude_end_ts)
      return [[], []] if rows.empty?

      # Find first row >= exclude_start_ts
      start_idx = BinarySearch.lower_bound(rows, exclude_start_ts) { |row| row[:timestamp] }

      # Find first row > exclude_end_ts
      end_idx = BinarySearch.upper_bound(rows, exclude_end_ts) { |row| row[:timestamp] }

      rows_before = start_idx > 0 ? rows[0...start_idx] : []
      rows_after = end_idx < rows.length ? rows[end_idx..-1] : []

      [rows_before, rows_after]
    end

    private_class_method :split_around_range
  end
end
