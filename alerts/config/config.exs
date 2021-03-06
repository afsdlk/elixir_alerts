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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

# YOUR DATA SOURCES
config :alerts,
  data_sources: %{
    "TEST MYSQL" => [
      DRIVER: "MySQL ANSI",
      SERVER: "test_mysql",
      DATABASE: "test",
      UID: "root",
      PWD: "mysql",
      INITSTMT: "SET SESSION TRANSACTION READ ONLY;"
    ],
    "TEST POSTGRES" => [
      DRIVER: "PostgreSQL Unicode",
      SERVER: "test_postgres",
      DATABASE: "test",
      PORT: 5433,
      UID: "postgres",
      PWD: "postgres",
      INITSTMT: "SET TRANSACTION ISOLATION LEVEL READ ONLY"
    ]
  }

config :swarm,
  nodes: [:":nonode@nohost"],
  sync_nodes_timeout: 0

config :alerts, ecto_repos: [Alerts.Repo]

config :alerts, git_browser: "http://localhost:8080/"
