# frozen_string_literal: true

require "json"

require_relative "../../util"
require_relative "../fetch/fetch_strategy"
require_relative "../shared/container"

module Eodhd
  module Fetch
    module_function

    def run
      container = Container.new(command: "fetch")
      strategy = FetchStrategy.new(
        log: container.logger,
        cfg: container.config,
        api: container.api,
        io: container.io
      )
      strategy.run
    end
  end
end
