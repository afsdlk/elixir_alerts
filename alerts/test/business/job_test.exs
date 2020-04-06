defmodule Business.JobsTest do
  use ExUnit.Case
  import Crontab.CronExpression

  require Alerts.Scheduler
  alias Alerts.Business.Jobs, as: J

  defmodule(SendingProcess, do: def(run(pid, name), do: send(pid, name)))

  test "saving jobs" do
    name = CustomHelper.random_atom()
    pid = self()

    assert name
           |> J.save(fn -> SendingProcess.run(pid, name) end, "@reboot")
           |> Alerts.Scheduler.find_job() !== nil

    assert_receive name, 2_000

    assert CustomHelper.random_atom()
           |> J.save(fn -> :ok end, "")
           |> Alerts.Scheduler.find_job() == nil
  end

  test "saving jobs error handling" do
    assert_raise FunctionClauseError, ~r/^.*Quantum.Job.set_name.*$/, fn ->
      J.save("string instead of atom", fn -> :ok end, "@reboot")
    end

    assert_raise RuntimeError, ~r/^Can't parse .* as minute.$/, fn ->
      J.save(:atom, fn -> :ok end, "wrong schedule")
    end
  end

  test "deleting jobs" do
    assert CustomHelper.random_atom()
           |> J.save(fn -> :ok end, "@reboot")
           |> J.delete()
           |> Alerts.Scheduler.find_job() == nil

    assert CustomHelper.random_atom()
           |> J.delete()
           |> Alerts.Scheduler.find_job() == nil
  end

  test "updating jobs" do
    new_function = fn -> :ok2 end

    job =
      CustomHelper.random_atom()
      |> J.save(fn -> :ok end, "@reboot")
      |> J.update(new_function, "* * * * *")
      |> Alerts.Scheduler.find_job()

    assert job.task == new_function
    assert job.schedule == ~e[* * * * * *]

    assert CustomHelper.random_atom()
           |> J.save(fn -> :ok end, "@reboot")
           |> J.update(fn -> :ok end, "")
           |> Alerts.Scheduler.find_job() == nil

    assert CustomHelper.random_atom()
           |> J.save(fn -> :ok end, "@reboot")
           |> J.update(fn -> :ok end, nil)
           |> Alerts.Scheduler.find_job() == nil
  end
end
