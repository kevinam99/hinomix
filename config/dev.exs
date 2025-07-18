import Config

# Configure your database
config :hinomix, Hinomix.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "hinomix_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
config :hinomix, HinomixWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "egyEa5/05rzh5imUNydQJRyx8mKJPvx3aB/rn/rnfK9tSCcIKhlP+QOJIlBK+2Sn",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:hinomix, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:hinomix, ~w(--watch)]}
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :default_formatter, format: "[$level] $message\n"

# Disable debug logs for cleaner output
config :logger, level: :debug

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false
