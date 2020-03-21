# Just once

# Create new app without docker file
docker build -t alerts:latest -<<EOF
FROM elixir:1.6.1
EOF

# Just once: Create your new phoenix project
docker container run  --rm -v /Users/juanse/experiments/Alerts:/app -w /app -it alerts:latest bash -c " mix local.hex --force; mix local.rebar --force; mix archive.install --force https://github.com/phoenixframework/archives/raw/master/phx_new.ez; mix phx.new alerts"

docker-compose up


docker exec -it alerts_phoenix bash -c "mix deps.compile file_system"

docker exec -it alerts_phoenix bash -c "mix test"
docker exec -it alerts_db bash -c "psql -U postgres"
docker exec -it alerts_db bash -c "psql -U postgres alerts_dev"

docker exec -it alerts_phoenix bash -c "iex --erl '-kernel shell_history enabled' -S mix"

docker exec -it alerts_phoenix bash -c "mix format mix.exs 'lib/**/*.{ex,exs}' 'test/**/*.{ex,exs}'"


Ecto.Adapters.SQL.stream(Oracle.Repo, "SELECT $1::integer + $2", [40, 2], max_rows: 10)

Oracle.Repo.transaction(fn -> Oracle.Repo |> Ecto.Adapters.SQL.stream("SELECT * FROM HELP", [], max_rows: 10) |> Stream.map(&(&1.rows)) |> Enum.to_list() end)

Oracle.Repo |> Ecto.Adapters.SQL.stream("SELECT * FROM HELP", [], max_rows: 10) |> Stream.map(&(&1.rows)) |> Enum.to_list()