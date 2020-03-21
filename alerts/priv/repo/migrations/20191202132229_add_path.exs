defmodule Alerts.Repo.Migrations.AddPath do
  use Ecto.Migration

  def change do
    alter table(:alert) do
      add(:path, :varchar)
    end
  end
end
