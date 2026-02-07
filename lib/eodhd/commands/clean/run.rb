# frozen_string_literal: true

module Eodhd
  module Commands
    module Clean
      class Run
        def initialize(container:)
          @log = container.logger
          @io = container.io
        end

        def clean_exchanges(yes:)
          if confirm_clean("exchanges list", yes)
            @io.delete_dir("exchanges-list.json")
            @log.info("Deleted exchanges list")
          else
            @log.info("Cancelled")
          end
        end

        def clean_symbols(yes:)
          if confirm_clean("symbols", yes)
            @io.delete_dir("symbols")
            @log.info("Deleted symbols")
          else
            @log.info("Cancelled")
          end
        end

        private

        def confirm_clean(name, yes)
          return true if yes

          print "Are you sure you want to delete #{name}? (y/N): "
          response = $stdin.gets
          response&.strip&.downcase == "y"
        end
      end
    end
  end
end
