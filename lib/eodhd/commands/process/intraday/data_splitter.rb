# frozen_string_literal: true

require "date"

module Eodhd
  module Commands
    module Process
      module Intraday
        class DataSplitter
          YearMonth = Data.define(:year, :month) do
        def to_s
          "#{year}-#{month.to_s.rjust(2, "0")}"
        end
      end

      class << self
        def by_month(data)
          return [] if data.nil? || data.empty?

          grouped = data.group_by do |row|
            datetime_str = row[:datetime]
            date_str = datetime_str.split(" ", 2).first
            date = Date.iso8601(date_str)
            YearMonth.new(date.year, date.month)
          end

          grouped
            .sort_by { |year_month, _| [year_month.year, year_month.month] }
            .map { |year_month, rows| { key: year_month, value: rows } }
        end
          end
        end
      end
    end
  end
end
