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
          clean(
            target_name: "exchanges list",
            target_path: Eodhd::Shared::Path.exchanges_file,
            yes: yes,
            dry_run: dry_run
          )
        end

        def symbols(yes:, dry_run: false)
          clean(
            target_name: "symbols",
            target_path: Eodhd::Shared::Path.symbols_dir,
            yes: yes,
            dry_run: dry_run
          )
        end

        def meta(yes:, dry_run: false)
          clean(
            target_name: "meta",
            target_path: Eodhd::Shared::Path.meta_dir,
            yes: yes,
            dry_run: dry_run
          )
        end

        def raw(yes:, dry_run: false)
          clean(
            target_name: "raw",
            target_path: Eodhd::Shared::Path.raw_dir,
            yes: yes,
            dry_run: dry_run
          )
        end

        def raw_eod(yes:, dry_run: false)
          clean(
            target_name: "raw eod",
            target_path: Eodhd::Shared::Path.raw_eod_dir,
            yes: yes,
            dry_run: dry_run
          )
        end

        def raw_intraday(yes:, dry_run: false)
          clean(
            target_name: "raw intraday",
            target_path: Eodhd::Shared::Path.raw_intraday_dir,
            yes: yes,
            dry_run: dry_run
          )
        end

        def data(yes:, dry_run: false)
          clean(
            target_name: "data",
            target_path: Eodhd::Shared::Path.data_dir,
            yes: yes,
            dry_run: dry_run
          )
        end

        def data_eod(yes:, dry_run: false)
          clean(
            target_name: "data eod",
            target_path: Eodhd::Shared::Path.data_eod_dir,
            yes: yes,
            dry_run: dry_run
          )
        end

        def data_intraday(yes:, dry_run: false)
          clean(
            target_name: "data intraday",
            target_path: Eodhd::Shared::Path.data_intraday_dir,
            yes: yes,
            dry_run: dry_run
          )
        end

        def log(yes:, dry_run: false)
          clean(
            target_name: "log",
            target_path: Eodhd::Shared::Path.log_dir,
            yes: yes,
            dry_run: dry_run
          )
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
