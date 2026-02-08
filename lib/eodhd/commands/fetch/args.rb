# frozen_string_literal: true

module Eodhd
  module Commands
    module Fetch
      class Args
        VALID_SUBCOMMANDS = %w[exchanges symbols meta eod intraday].freeze

        def initialize(container:)
          @impl = Eodhd::Args::SubcommandsArgs.new(
            container: container,
            command_name: "fetch",
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