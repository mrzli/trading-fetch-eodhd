# frozen_string_literal: true

module Eodhd
  module Shared
    class Path
      class << self
        # Exchanges - start
        def exchanges_file
          "exchanges.json"
        end
        # Exchanges - end

        # Symbols - start
        def symbols_dir
          "symbols"
        end

        def exchange_symbols_file(exchange, type)
          exchange, type = process_exchange_and_type(exchange, type)
          File.join(symbols_dir, exchange, "#{type}.json")
        end
        # Symbols - end

        # Meta - start
        def meta_dir
          "meta"
        end

        def splits(exchange, symbol)
          exchange, symbol = process_exchange_and_symbol(exchange, symbol)
          File.join(meta_dir, exchange, symbol, "splits.json")
        end

        def dividends(exchange, symbol)
          exchange, symbol = process_exchange_and_symbol(exchange, symbol)
          File.join(meta_dir, exchange, symbol, "dividends.json")
        end
        # Meta - end

        # Raw - start
        def raw_dir
          "raw"
        end

        def raw_eod_dir
          File.join(raw_dir, "eod")
        end

        def raw_eod_data(exchange, symbol)
          exchange, symbol = process_exchange_and_symbol(exchange, symbol)
          File.join(raw_eod_dir, exchange, "#{symbol}.csv")
        end

        def raw_intraday_dir
          File.join(raw_dir, "intraday")
        end

        def raw_intraday_fetched_dir
          File.join(raw_intraday_dir, "fetched")
        end

        def raw_intraday_fetched_symbol_data_dir(exchange, symbol)
          exchange, symbol = process_exchange_and_symbol(exchange, symbol)
          File.join(raw_intraday_fetched_dir, exchange, symbol)
        end

        def raw_intraday_fetched_symbol_data(exchange, symbol, from, to)
          dir_for_intraday_raw = raw_intraday_fetched_symbol_data_dir(exchange, symbol)

          from = Util::Validate.integer("from", from)
          from_formatted = Util::Date.seconds_to_datetime(from)

          to = Util::Validate.integer("to", to)
          to_formatted = Util::Date.seconds_to_datetime(to)

          File.join(dir_for_intraday_raw, "#{from_formatted}__#{to_formatted}.csv")
        end

        def raw_intraday_processed_dir
          File.join(raw_intraday_dir, "processed")
        end

        def raw_intraday_processed_symbol_data_dir(exchange, symbol)
          exchange, symbol = process_exchange_and_symbol(exchange, symbol)
          File.join(raw_intraday_processed_dir, exchange, symbol)
        end

        def raw_intraday_processed_symbol_year_month(exchange, symbol, year, month)
          dir = raw_intraday_processed_symbol_data_dir(exchange, symbol)
          year = Util::Validate.integer("year", year)
          month = Util::Validate.integer("month", month)
          File.join(dir, "#{year}-#{format('%02d', month)}.csv")
        end
        # Raw - end

        # Data - start
        def data_dir
          "data"
        end

        def data_eod_dir
          File.join(data_dir, "eod")
        end

        def processed_eod_data(exchange, symbol)
          exchange, symbol = process_exchange_and_symbol(exchange, symbol)
          File.join(data_eod_dir, exchange, "#{symbol}.csv")
        end

        def data_intraday_dir
          File.join(data_dir, "intraday")
        end

        def processed_intraday_data_dir(exchange, symbol)
          exchange, symbol = process_exchange_and_symbol(exchange, symbol)
          File.join(data_intraday_dir, exchange, symbol)
        end

        def processed_intraday_year_month(exchange, symbol, year, month)
          dir = processed_intraday_data_dir(exchange, symbol)
          year = Util::Validate.integer("year", year)
          month = Util::Validate.integer("month", month)
          File.join(dir, "#{year}-#{format('%02d', month)}.csv")
        end
        # Data - end

        def log_dir
          "log"
        end

        private

        def process_exchange_and_type(exchange, type)
          exchange = Util::Validate.required_string("exchange", exchange)
          type = Util::Validate.required_string("type", type)

          exchange = Util::String.kebab_case(exchange)
          type = Util::String.kebab_case(type)
          type = "unknown" if type.empty?

          [exchange, type]
        end

        def process_exchange_and_symbol(exchange, symbol)
          exchange = Util::Validate.required_string("exchange", exchange)
          symbol = Util::Validate.required_string("symbol", symbol)

          exchange = Util::String.kebab_case(exchange)
          symbol = Util::String.kebab_case(symbol)

          [exchange, symbol]
        end
      end
    end
  end
end
