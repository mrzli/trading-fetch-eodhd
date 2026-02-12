# Trading - Fetch EODHD

This is a collection of Ruby scripts used to fetch trading data from [EOD Historical Data](https://eodhistoricaldata.com/) and for processing it.

## Project Setup

### 1. Install Ruby

Confirm mise is installed and install the Ruby version declared in `.mise.toml`:

```bash
mise --version
mise install
```

Verify:

```bash
mise exec -- ruby -v
```

### 2. Install Gems

```bash
mise exec -- bundle install
```

Or if you have mise shell activation enabled:

```bash
bundle install
```

### 3. Make Scripts Executable

```bash
chmod +x bin/*
```

### 4. Setup Environment Variables

Copy the example env file and configure it:

```bash
cp .env.example .env
```

Edit `.env` and set your EODHD API key and any other necessary variables.

### 5. Using External Drive for Data (Optional)

```bash
sudo mount -t exfat -o uid=$(id -u),gid=$(id -g) /dev/disk/by-uuid/34D4-9F99 /home/mrzli/projects/ext
```

To unmount:

```bash
sync
sudo umount /home/mrzli/projects/ext
```

## Running Commands

All commands support `--help` flag to show usage information.

### Fetch Data

Fetches data from EODHD API.

```bash
./bin/fetch --help                           # Show help

# Fetch exchanges list
./bin/fetch exchanges          # Fetch exchanges
./bin/fetch exchanges --force  # Force fresh fetch

# Fetch symbols for exchanges
./bin/fetch symbols            # Fetch symbols (sequentially)
./bin/fetch symbols --parallel # Fetch symbols (parallel with default workers)
./bin/fetch symbols -p -w 8    # Fetch symbols (parallel with 8 workers)
./bin/fetch symbols -f -p      # Force fetch symbols in parallel

# Fetch metadata (splits and dividends)
./bin/fetch meta               # Fetch metadata (sequentially)
./bin/fetch meta --parallel    # Fetch metadata (parallel with default workers)
./bin/fetch meta -p -w 8       # Fetch metadata (parallel with 8 workers)
./bin/fetch meta -f -p         # Force fetch metadata in parallel

# Fetch EOD (end-of-day) data
./bin/fetch eod                # Fetch EOD (sequentially)
./bin/fetch eod --parallel     # Fetch EOD (parallel with default workers)
./bin/fetch eod -p -w 8        # Fetch EOD (parallel with 8 workers)
./bin/fetch eod -f -p          # Force fetch EOD in parallel

# Fetch intraday data
./bin/fetch intraday                  # Fetch intraday (sequentially)
./bin/fetch intraday --parallel       # Fetch intraday (parallel with default workers)
./bin/fetch intraday -p -w 8          # Fetch intraday (parallel with 8 workers)
./bin/fetch intraday --recheck-start-date 2025-01-01 -p  # Recheck from specific date
```

### Process Data

Processes fetched data (splits, dividends, price adjustments, merging).

```bash
./bin/process --help              # Show help

# Process EOD data
./bin/process eod                 # Process EOD data (sequentially)
./bin/process eod --parallel      # Process EOD data (parallel)
./bin/process eod -p -w 8         # Process EOD data (parallel with 8 workers)
./bin/process eod -f -p           # Force process EOD data in parallel

# Process intraday data
./bin/process intraday            # Process intraday data (sequentially)
./bin/process intraday --parallel # Process intraday data (parallel)
./bin/process intraday -p -w 8    # Process intraday data (parallel with 8 workers)
./bin/process intraday -f -p      # Force process intraday data in parallel
```

### Clean Data

Removes fetched/processed data.

```bash
./bin/clean --help       # Show help

# Clean exchanges data
./bin/clean exchanges    # Delete exchanges list (with confirmation)
./bin/clean exchanges -y # Delete exchanges list (skip confirmation)

# Clean symbols data
./bin/clean symbols      # Delete symbols (with confirmation)
./bin/clean symbols -y   # Delete symbols (skip confirmation)
```

## Architecture

### Directory Structure

- `bin/`: Command-line entry points (fetch, process, clean)
- `lib/`: Core library code
  - `eodhd/`: Main application namespace
    - `args/`: Shared argument parsing utilities
    - `commands/`: Top-level command implementations
      - `fetch/`: Data fetching logic
        - `subcommands/`: Fetch subcommands (exchanges, symbols, meta, eod, intraday)
      - `process/`: Data processing logic
        - `subcommands/`: Process subcommands (eod, intraday)
        - `shared/`: Processing utilities (splits, dividends, price adjustments)
      - `clean/`: Data cleaning logic
    - `shared/`: Shared utilities across commands
      - `parsing/`: CSV and JSON parsers
      - `processing/`: Data processing components
  - `logging/`: Logging infrastructure (console, file, null sinks)
  - `util/`: General utilities (date, string, validation, binary search, parallel execution)
- `test/`: Test suite mirroring `lib/` structure
- `docs/`: Project documentation

### Key Components

- **Dependency Injection**: Uses `Eodhd::Shared::Container` for IoC
- **Configuration**: Environment-based configuration via `.env` file
- **Logging**: Structured logging with multiple sink support (console, file)
- **Parallel Processing**: Configurable worker-based parallel execution for fetch/process operations
- **Data Parsing**: Specialized parsers for CSV (EOD, intraday) and JSON (splits, dividends)
- **Autoloading**: Uses Zeitwerk for automatic code loading based on file structure
