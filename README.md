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

## Running Commands

### Fetch Data

```bash
./bin/fetch --help                           # Show help

# Fetch exchanges list
./bin/fetch exchanges          # Fetch exchanges
./bin/fetch exchanges --force  # Force fresh fetch

# Fetch symbols
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
./bin/fetch intraday           # Fetch intraday (sequentially)
./bin/fetch intraday --parallel # Fetch intraday (parallel with default workers)
./bin/fetch intraday -p -w 8   # Fetch intraday (parallel with 8 workers)
```

### Process Data

```bash
./bin/process --help              # Show help
./bin/process eod                 # Process EOD data
./bin/process intraday            # Process intraday data
```

## Architecture

- `bin/`: Command entry points
- `lib/eodhd/`: Core library code
  - `commands/`: CLI command handlers
  - `fetch/`: Fetching logic and components
  - `process/`: Processing logic
  - `shared/`: Shared utilities (config, logging, IoC container, etc.)
