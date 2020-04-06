defmodule Business.LibTest do
  use ExUnit.Case
  alias Alerts.Scheduler
  alias Alerts.Business.Files, as: Files
  alias Alerts.Business.Alerts, as: Lib

  test "create alert in db, creates destination folder and scheduling job" do
    {:ok, inserted} =
      %{
        name: CustomHelper.random_name(),
        context: "test",
        query: "SELECT 'a' AS a;",
        description: "test",
        repo: "test",
        folder: CustomHelper.random_name(),
        schedule: "* * * * *"
      }
      |> Lib.create()

    assert inserted |> Lib.get!() !== nil
    assert inserted |> Files.basename() |> File.exists?() == true
    assert inserted |> Lib.get_job_name() |> Scheduler.find_job() !== nil

    {:ok, updated} =
      inserted
      |> Lib.update(%{
        name: inserted.name,
        context: inserted.context,
        query: inserted.query,
        description: inserted.description,
        repo: inserted.repo,
        folder: CustomHelper.random_name(),
        schedule: ""
      })

    assert updated |> Lib.get_job_name() |> Scheduler.find_job() == nil
    assert inserted |> Files.basename() |> File.exists?() == true
    assert updated |> Files.basename() |> File.exists?() == true
  end
end
