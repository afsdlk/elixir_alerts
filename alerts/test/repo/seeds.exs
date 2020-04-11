# Script for populating the database. You can run it as:
#
#     mix run test/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Alerts.Repo.insert!(%Alerts.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

require Logger

old_level = Logger.level()
Logger.configure(level: :info)
Logger.info("Adding test fixtures")

a1 = %Alerts.Business.DB.Alert{
  id: 100_000_000,
  context: "TESTS",
  description: "Testing 123",
  inserted_at: ~N[2020-03-21 16:34:35],
  last_run: ~N[2020-03-25 08:26:09],
  name: "test1",
  path: "esg",
  query: "SELECT * FROM book;",
  source: "MYSQL TEST",
  results_size: 1,
  schedule: nil,
  status: "under threshold",
  threshold: 10,
  updated_at: ~N[2020-03-25 08:26:04]
}

Alerts.Repo.insert!(a1)

Logger.info("Test fixtures ADDED")
Logger.configure(level: old_level)
