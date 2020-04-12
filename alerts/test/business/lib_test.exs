defmodule Business.LibTest do
  use ExUnit.Case
  alias Alerts.Scheduler
  alias Alerts.Business.DB.Alert, as: A
  alias Alerts.Business.Alerts, as: Lib
  alias CustomHelper, as: H

  import Crontab.CronExpression

  # @base_folder Application.get_env(:alerts, :export_folder)

  @default %{
    "query" => "SELECT 'a' AS a;",
    "description" => "test",
    "source" => "TEST MYSQL"
  }

  # alerts are atom maps, vs string maps pars
  defp deatomize(map) do
    for {key, val} <- map, into: %{} do
      case is_atom(key) do
        true -> {Atom.to_string(key), val}
        false -> {key, val}
      end
    end
  end

  defp fixture_struct(),
    do: @default |> Map.merge(%{"name" => H.random_name(), "context" => H.random_name()})

  defp fixture_struct(%A{} = alert),
    do: fixture_struct() |> Map.merge(alert |> Map.from_struct() |> deatomize())

  defp fixture_struct(m),
    do: fixture_struct() |> Map.merge(m)

  defp fixture_struct(%A{} = alert, map),
    do: alert |> Map.from_struct() |> deatomize() |> Map.merge(map)

  defp fixture_struct_with_schedule(s),
    do: %{"schedule" => s} |> fixture_struct()

  defp fixture_struct_with_schedule(%A{} = alert, s),
    do: alert |> fixture_struct(%{"schedule" => s})

  test "create alert db fields" do
    with {:ok, inserted} = fixture_struct() |> Lib.create() do
      assert inserted |> Lib.get!() !== nil
      assert inserted.path == nil
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

  test "update alert db fields" do
    with {:ok, inserted} = fixture_struct_with_schedule("@reboot") |> Lib.create() do
      updated_fields = %{
        "description" => H.random_name(),
        "name" => H.random_name(),
        "query" => "SELECT '#{H.random_name()}' as \"#{H.random_name()}\""
      }

      pars = inserted |> fixture_struct(updated_fields)
      {:ok, updated} = inserted |> Lib.update(pars)

      assert updated.path == nil
      assert updated.description == updated_fields["description"]
      assert updated.name == updated_fields["name"]
      assert updated.query == updated_fields["query"]
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

  test "run updates results_size, status and saves the file creating the folder" do
    with run <- fixture_struct() |> Lib.create() |> Lib.run() do
      updated_fields = %{
        "query" => """
          (SELECT '#{H.random_name()}' as \"#{H.random_name()}\")
          UNION
          (SELECT '#{H.random_name()}' as \"#{H.random_name()}\")
          UNION
          (SELECT '#{H.random_name()}' as \"#{H.random_name()}\")
        """,
        "threshold" => 5,
        "context" => H.random_name()
      }

      pars = run |> fixture_struct(updated_fields)
      run_updated = run |> Lib.update(pars) |> Lib.run()

      assert run.results_size == 1
      assert run.status == "bad"
      assert File.exists?(run.path) == true
      assert run.path != run_updated.path
      assert run_updated.results_size == 3
      assert run_updated.status == "under threshold"
      assert File.exists?(run_updated.path) == true
    end
  end
end
