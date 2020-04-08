defmodule Alerts.Repo.Migrations.DropResultsField do
  use Ecto.Migration

  def change do
    alter table(:alert) do
      remove(:results)
    end
  end
end
