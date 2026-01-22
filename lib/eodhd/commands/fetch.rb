# frozen_string_literal: true

require "json"

require_relative "../../util"
require_relative "../fetch/args"
require_relative "../fetch/fetch_strategy"
require_relative "../shared/container"

module Eodhd
  module Fetch
    module_function

    def run
      subcommand, force = FetchArgs.parse(ARGV)

      container = Container.new(command: "fetch")
      strategy = FetchStrategy.new(container: container)

      case subcommand
      when "exchanges"
        strategy.run_exchanges(force: force)
      when "symbols"
        strategy.run_symbols
      end
    end
  end
end
