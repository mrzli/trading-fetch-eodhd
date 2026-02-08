# frozen_string_literal: true

module Eodhd
  module Commands
    module Clean
      module_function

      def run
        command, yes = Args.parse(ARGV).deconstruct

        container = Eodhd::Shared::Container.new(command: "clean")
        runner = Runner.new(container: container)

        case command
        when "exchanges"
          runner.exchanges(yes: yes)
        when "symbols"
          runner.symbols(yes: yes)
        end
      end
    end
  end
end
