# Project Instructions for GitHub Copilot

## Code Quality Checks

- Always run `rake test` after making changes
- Check Ruby syntax with `ruby -c` for modified files
- Ensure proper 2-space indentation
- After modifying bin/ scripts or lib/ code, verify commands work with help mode:
  - `./bin/fetch --help` or `./bin/fetch <subcommand> --help`
  - `./bin/process --help` or `./bin/process <subcommand> --help`
  - `./bin/clean --help` or `./bin/clean <subcommand> --help`
  - NEVER run commands without `--help` flag (to avoid actual data fetching/processing)

## Zeitwerk Conventions

- Files in `lib/util/` map to `Util::*` namespace
- Files in `lib/logging/` map to `Logging::*` namespace (loaded via `lib/logging.rb`)
- Class names must match file names (e.g., `date.rb` → `Util::Date`)
- `lib/logging.rb` (not `logger.rb`) to avoid conflict with stdlib `logger` gem

## Before Completing Tasks

- [ ] Run syntax check on all modified Ruby files
- [ ] Run full test suite
- [ ] Verify no references to old class names remain

## Naming Conventions

- Use snake_case for file names
- No `_util` or `_helper` suffixes (namespace provides context)
- Test files mirror source files: `date.rb` → `date_test.rb`
