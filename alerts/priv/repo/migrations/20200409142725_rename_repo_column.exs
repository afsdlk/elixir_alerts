defmodule Alerts.Repo.Migrations.RenameRepoColumn do
  use Ecto.Migration

  def change do
    rename(table("alert"), :repo, to: :source)
  end
end
