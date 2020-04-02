# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :alerts, AlertsWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "TMJc/uu7gXWWuF6L4uk8aBhiDEy6OsYm57cAznECtzHNsZ5s9u3HLxw81f+/yqK4",
  render_errors: [view: AlertsWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Alerts.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :phoenix, :template_engines,
  slim: PhoenixSlime.Engine,
  slime: PhoenixSlime.Engine

config :slime, :keep_lines, true

config :alerts, :repo_prefix, "Elixir.Alerts.Business.Repos."

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

# General application configuration
config :alerts, ecto_repos: [Alerts.Repo]

# Configure your database
config :alerts, Alerts.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "alerts_dev",
  hostname: "db",
  port: 5432,
  pool_size: 10
