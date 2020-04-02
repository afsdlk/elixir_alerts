use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :alerts, AlertsWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
config :logger, :console, format: "$time - [$level] $message\n"

# Configure your database
config :alerts, Alerts.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "alerts_test",
  hostname: "db",
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox
