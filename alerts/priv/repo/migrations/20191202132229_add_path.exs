defmodule Alerts.Repo.Migrations.AddPath do
  use Ecto.Migration

  def change do
    alter table(:pyz_alert) do
      add :path, :varchar
    end
  end
end
