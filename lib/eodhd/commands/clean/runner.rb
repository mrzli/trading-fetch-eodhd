# frozen_string_literal: true

module Eodhd
  module Commands
    module Clean
      class Runner
        def initialize(container:)
          @log = container.logger
          @io = container.io
        end

        def exchanges(yes:, dry_run: false)
          clean(target_name: "exchanges list", target_path: "exchanges-list.json", yes: yes, dry_run: dry_run)
        end

        def symbols(yes:, dry_run: false)
          clean(target_name: "symbols", target_path: "symbols", yes: yes, dry_run: dry_run)
        end

        private

        def clean(target_name:, target_path:, yes:, dry_run:)
          if dry_run
            full_path = @io.output_path(target_path)
            @log.info("Dry run: would delete #{Util::String::truncate_middle(full_path)}")
            return
          end

          if confirm_clean(target_name, yes)
            @io.delete_dir(target_path)
            @log.info("Deleted #{target_name}")
          else
            @log.info("Cancelled")
          end
        end

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
