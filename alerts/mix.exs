defmodule Alerts.Mixfile do
  use Mix.Project

  def project do
    [
      app: :alerts,
      version: "0.0.1",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Alerts.Application, []},
      extra_applications: [:logger, :runtime_tools, :odbc]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.9"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 4.0.0"},
      {:ecto_sql, "~> 3.0-rc.1"},
      {:db_connection, "~> 2.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:plug_cowboy, "~> 1.0"},
      {:quantum, "~> 2.3"},
      {:poison, "~> 3.0"},
      {:timex, "~> 3.1"},
      {:csv, "~> 2.3"},
      {:phoenix_slime, "~> 0.10.0"},
      {:slime, "~> 1.2"},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:slugger, "~> 0.3"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: [
        "ecto.drop",
        "ecto.create",
        "ecto.migrate",
        "run test/repo/seeds.exs",
        "test"
      ]
    ]
  end
end
