#!/usr/bin/env bash
set -e

# Wait for Postgres to become available.
export PGPASSWORD=postgres
until psql -p 5432 -h db -U "postgres" -c '\q' 2>/dev/null; do
  >&2 echo "\nPostgres is unavailable - sleeping"
  sleep 1
done

# echo "\nMigrating..." mix ecto.drop mix ecto.create -r Alerts.Repo
mix ecto.create -r Alerts.Repo
mix ecto.migrate -r Alerts.Repo

# update package manager
echo 'Y' | mix local.hex

# install node dependencies
# npm audit fix --force --prefix assets
npm install --prefix assets

# update elixir dependencies
mix deps.get

# run phoenix
PORT=4000 mix phx.server
