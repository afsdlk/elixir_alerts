defmodule Alerts.Repo.Migrations.CreateAlerts do
  use Ecto.Migration

  def change do

    create table(:pyz_alert) do
      add :context, :varchar, null: false
      add :name, :varchar, null: false
      add :query, :text, null: false

      add :description, :text

      add :last_run, :timestamp

      timestamps()

      add :results, :text
      add :results_size, :integer
      add :threshold, :integer, default: 0

      add :schedule, :varchar

      add :status, :varchar, default: "never_run"
      add :repo, :varchar
    end
  end
end
