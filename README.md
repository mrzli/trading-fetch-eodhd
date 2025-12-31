# trading-fetch-eodhd

Minimal Ruby app (managed by mise) that prints a message.

## Step by step

1. Confirm mise is installed:

```bash
mise --version
```

2. Install the Ruby version declared in .mise.toml:

```bash
mise install
```

3. Verify the Ruby version mise will use in this folder:

```bash
mise current
mise exec -- ruby -v
```

4. Run the script:

```bash
chmod +x bin/hello
./bin/hello
```

## Using an external library (minimum)

This repo includes a Gemfile and uses the `colorize` gem.

1. Install gems (under the mise Ruby):

```bash
mise exec -- bundle install
```

2. Run:

```bash
./bin/hello
```

## Using an env var (dotenv)

Yes, `dotenv` is commonly used in Ruby apps to load environment variables from a local `.env` file.
It’s mainly for local development; in production you typically set real env vars (and don’t use `.env`).

1. Create a local env file:

```bash
cp .env.example .env
```

2. Install gems (if you haven’t yet):

```bash
mise exec -- bundle install
```

3. Run:

```bash
./bin/hello
```

## Suggested structure (standard Ruby pattern)

Yes—this is normal/standard: keep `bin/*` as thin wrappers and put the “meat” in `lib/`.

- `bin/fetch`: reads env/args and calls library code
- `lib/trading_fetch_eodhd/fetch.rb`: implements the actual HTTP + file writing

## Fetch CSV (MCD.US)

`bin/fetch` fetches CSV for `MCD.US` and writes it to `EODHD_OUTPUT_DIR/MCD.US.csv`.

1. Set required env vars (recommended via `.env`):

```bash
cp .env.example .env
# edit .env: set EODHD_API_TOKEN and EODHD_OUTPUT_DIR
```

2. Run:

```bash
./bin/fetch
```

If you have mise shell activation enabled, you can also run `ruby -v` directly.
