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

If you have mise shell activation enabled, you can also run `ruby -v` directly.
