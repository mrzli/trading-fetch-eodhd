# frozen_string_literal: true

module Eodhd
  module Commands
    module Clean
      module_function

      def run
        command, yes = Args.parse(ARGV).deconstruct

        container = Eodhd::Shared::Container.new(command: "clean")
        strategy = Run.new(container: container)

        case command
        when "exchanges"
          strategy.clean_exchanges(yes: yes)
        when "symbols"
          strategy.clean_symbols(yes: yes)
        end
      end
    end
  end
end
