# frozen_string_literal: true

require "json"

module Eodhd
  module Commands
    module Fetch
      module Subcommands
        module Exchanges
          class Runner
            def initialize(container:, shared:)
              @log = container.logger
              @api = container.api
              @io = container.io
              @shared = shared
            end

            def fetch(force:)
              relative_path = Eodhd::Shared::Path.exchanges_file

              if force || @shared.file_stale?(relative_path)
                @log.info("Fetching exchanges list#{force ? ' (forced)' : ''}...")
                fetched = @api.get_exchanges_list_json
                saved_path = @io.write_json(relative_path, fetched, true)
                @log.info("Wrote #{Util::String.truncate_middle(saved_path)}")
              else
                @log.info("Skipping exchanges list (fresh): #{relative_path}.")
              end
            end

          end
        end
      end
    end
  end
end
