# frozen_string_literal: true

module Eodhd
  module Commands
    module Process
      class Args
        VALID_SUBCOMMANDS = %w[eod intraday].freeze

        def initialize(container:)
          @impl = Eodhd::Args::SubcommandsArgs.new(
            container: container,
            command_name: "process",
            valid_subcommands: VALID_SUBCOMMANDS
          )
        end

        def parse(argv)
          @impl.parse(argv)
        end
      end
    end
  end
end