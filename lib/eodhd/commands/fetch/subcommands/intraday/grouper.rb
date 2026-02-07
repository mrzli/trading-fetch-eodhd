# frozen_string_literal: true


module Eodhd
  module Commands
    module Fetch
      module Subcommands
        module Intraday
          class Grouper
            class << self
              # Groups sorted rows by year-month using binary search
              # @param rows [Array<Hash>] Sorted rows by timestamp
              # @return [Hash] Hash with [year, month] keys and row arrays as values
              def group_by_month(rows)
                return {} if rows.nil? || rows.empty?

                first_time = Time.at(rows.first[:timestamp]).utc
                last_time = Time.at(rows.last[:timestamp]).utc

                first_year_month = [first_time.year, first_time.month]
                last_year_month = [last_time.year, last_time.month]

                year_months = enumerate_year_months(first_year_month, last_year_month)

                grouped = {}
                year_months.each do |year, month|
                  month_rows = extract_month_rows(rows, year, month)
                  grouped[[year, month]] = month_rows unless month_rows.empty?
                end

                grouped
              end

              private

              # Enumerate all year-months between first and last (inclusive)
              # @param first_year_month [Array(Integer, Integer)] [year, month]
              # @param last_year_month [Array(Integer, Integer)] [year, month]
              # @return [Array<Array(Integer, Integer)>] Array of [year, month] pairs
              def enumerate_year_months(first_year_month, last_year_month)
                first_year, first_month = first_year_month
                last_year, last_month = last_year_month

                result = []
                year = first_year
                month = first_month

                loop do
                  result << [year, month]
                  break if year == last_year && month == last_month

                  month += 1
                  if month > 12
                    month = 1
                    year += 1
                  end
                end

                result
              end

              # Extract rows for a specific year-month using binary search
              # @param rows [Array<Hash>] Sorted rows by timestamp
              # @param year [Integer] Year
              # @param month [Integer] Month
              # @return [Array<Hash>] Rows within the specified month
              def extract_month_rows(rows, year, month)
                start_ts = Time.new(year, month, 1, 0, 0, 0, "+00:00").to_i
                end_ts = month_end_timestamp(year, month)

                start_idx = Util::BinarySearch.lower_bound(rows, start_ts) { |row| row[:timestamp] }
                end_idx = Util::BinarySearch.upper_bound(rows, end_ts) { |row| row[:timestamp] }

                return [] if start_idx >= rows.length || end_idx <= start_idx

                rows[start_idx...end_idx]
              end

              # Get the last timestamp of a given year-month
              # @param year [Integer] Year
              # @param month [Integer] Month
              # @return [Integer] Last second of the month as Unix timestamp
              def month_end_timestamp(year, month)
                next_month = month + 1
                next_year = year
                if next_month > 12
                  next_month = 1
                  next_year += 1
                end

                Time.new(next_year, next_month, 1, 0, 0, 0, "+00:00").to_i - 1
              end
            end
          end
        end
      end
    end
  end
end
