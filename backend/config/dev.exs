use Mix.Config

# Configure your database
config :spendable, Spendable.Repo, database: "spendable_dev"

# For development, we disable any cache and enable
# debugging and code reloading.
config :spendable, Spendable.Web.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :spendable, Plaid, base_url: "https://sandbox.plaid.com"

config :pigeon, :apns,
  apns_default: %{
    cert: {:spendable, "apns/cert.pem"},
    key: {:spendable, "apns/key.pem"},
    mode: :dev
  }

if File.exists?("config/dev.secret.exs") do
  import_config "dev.secret.exs"
end
