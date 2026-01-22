# frozen_string_literal: true

require_relative "../clean/args"
require_relative "../clean/clean_strategy"
require_relative "../shared/container"

module Eodhd
  module Clean
    module_function

    def run
      command, yes = CleanArgs.parse(ARGV).deconstruct

      container = Container.new(command: "clean")
      strategy = CleanStrategy.new(container: container)

      case command
      when "exchanges"
        strategy.clean_exchanges(yes: yes)
      when "symbols"
        strategy.clean_symbols(yes: yes)
      end
    end
  end
end
