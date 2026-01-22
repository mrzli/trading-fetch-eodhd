# frozen_string_literal: true

require "json"

require_relative "../../util"
require_relative "../fetch/args"
require_relative "../fetch/fetch_strategy"
require_relative "../shared/container"

module Eodhd
  module Fetch
    module_function

    def run()
      args = FetchArgs.parse(ARGV)
      subcommand = args.subcommand

      container = Container.new(command: "fetch")
      strategy = FetchStrategy.new(
        log: container.logger,
        cfg: container.config,
        api: container.api,
        io: container.io
      )

      case subcommand
      when "exchanges"
        strategy.run_exchanges
      when "symbols"
        strategy.run_symbols
      end
    end
  end
end
