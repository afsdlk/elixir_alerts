defmodule Business.LibTest do
  use ExUnit.Case
  alias Alerts.Scheduler
  alias Alerts.Business.DB.Alert, as: A
  alias Alerts.Business.Files, as: Files
  alias Alerts.Business.Alerts, as: Lib
  alias CustomHelper, as: H

  import Crontab.CronExpression

  # @base_folder Application.get_env(:alerts, :export_folder)

  @default %{
    query: "SELECT 'a' AS a;",
    description: "test",
    repo: "test"
  }

  defp fixture_struct(),
    do: @default |> Map.merge(%{name: H.random_name(), context: H.random_name()})

  defp fixture_struct(%A{} = a), do: fixture_struct() |> Map.merge(Map.from_struct(a))
  defp fixture_struct(m), do: fixture_struct() |> Map.merge(m)
  defp fixture_struct(%A{} = a, m), do: a |> Map.from_struct() |> Map.merge(m)
  defp fixture_struct_new_context(%A{} = a), do: fixture_struct(a, %{context: H.random_name()})
  defp fixture_struct_with_schedule(s), do: %{schedule: s} |> fixture_struct()
  defp fixture_struct_with_schedule(alert, s), do: fixture_struct(alert, %{schedule: s})

  test "create alert in db" do
    # Exists
    with {:ok, inserted} = fixture_struct() |> Lib.create() do
      assert inserted |> Lib.get!() !== nil
    end
  end

  test "create alert in db and scheduling jobs" do
    # Creates schedule
    with {:ok, inserted} = fixture_struct_with_schedule("@reboot") |> Lib.create() do
      assert inserted |> Lib.get_job_name() |> Scheduler.find_job() !== nil
    end

    # Does not create schedule
    with {:ok, inserted} = fixture_struct() |> Lib.create() do
      assert inserted |> Lib.get_job_name() |> Scheduler.find_job() == nil
    end
  end

  test "create alert in db and creating corresponding folder" do
    # Creates the folder (context)
    with {:ok, inserted} = fixture_struct() |> Lib.create() do
      assert inserted |> Files.basename() |> File.exists?() == true
      assert inserted |> Files.basename() == inserted.path
    end
  end

  test "updating an alert in db" do
    # Exists
    # Deletes scheduling job on update
    with {:ok, inserted} = fixture_struct_with_schedule("@reboot") |> Lib.create() do
      updated_fields = %{
        description: H.random_name(),
        name: H.random_name()
      }

      pars = inserted |> fixture_struct(updated_fields)
      {:ok, updated} = inserted |> Lib.update(pars)

      assert updated.description == updated_fields.description
      assert updated.name == updated_fields.name
    end
  end

  test "update alert in db and scheduling jobs" do
    # Deletes scheduling job on update
    with {:ok, inserted} = fixture_struct_with_schedule("@reboot") |> Lib.create() do
      pars = inserted |> fixture_struct_with_schedule("")
      {:ok, updated} = inserted |> Lib.update(pars)

      assert updated |> Lib.get_job_name() |> Scheduler.find_job() == nil
    end

    # Creates scheduling job on update
    with {:ok, inserted} = fixture_struct() |> Lib.create() do
      pars = inserted |> fixture_struct_with_schedule("* * * * *")
      {:ok, updated} = inserted |> Lib.update(pars)

      assert updated |> Lib.get_job_name() |> Scheduler.find_job() !== nil
    end

    # Modifies scheduling job on update
    with {:ok, inserted} = fixture_struct_with_schedule("@reboot") |> Lib.create() do
      pars = inserted |> fixture_struct_with_schedule("* * * * *")
      {:ok, updated} = inserted |> Lib.update(pars)

      assert (updated |> Lib.get_job_name() |> Scheduler.find_job()).schedule == ~e[* * * * * *]
    end
  end

  test "update alert in db and creating folder path" do
    # Creates folder on update
    with {:ok, inserted} = fixture_struct() |> Lib.create() do
      pars = inserted |> fixture_struct_new_context()
      {:ok, updated} = inserted |> Lib.update(pars)
      # both folders exist, meaning it does not delete the previous folder
      assert inserted |> Files.basename() |> File.exists?() == true
      assert updated |> Files.basename() |> File.exists?() == true
      assert Files.basename(inserted) != Files.basename(updated)
      assert Files.basename(updated) == updated.path
    end
  end
end
