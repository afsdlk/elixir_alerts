defmodule Business.JobsTest do
  use ExUnit.Case
  import Crontab.CronExpression

  require Alerts.Scheduler
  alias Alerts.Business.Jobs, as: J

  defp random_name() do
    :crypto.strong_rand_bytes(32)
    |> Base.encode64()
    |> binary_part(0, 32)
    |> String.to_atom()
  end

  defmodule(SendingProcess, do: def(run(pid, name), do: send(pid, name)))

  test "Test save job" do
    name = random_name()
    pid = self()

    assert name
           |> J.save(fn -> SendingProcess.run(pid, name) end, "@reboot")
           |> Alerts.Scheduler.find_job() !== nil

    assert_receive name, 2_000

    assert random_name()
           |> J.save(fn -> :ok end, "")
           |> Alerts.Scheduler.find_job() == nil
  end

  test "Test save job errors" do
    assert_raise FunctionClauseError, ~r/^.*Quantum.Job.set_name.*$/, fn ->
      J.save("string instead of atom", fn -> :ok end, "@reboot")
    end

    assert_raise RuntimeError, ~r/^Can't parse .* as minute.$/, fn ->
      J.save(:atom, fn -> :ok end, "wrong schedule")
    end
  end

  test "Test deleting a job" do
    assert random_name()
           |> J.save(fn -> :ok end, "@reboot")
           |> J.delete()
           |> Alerts.Scheduler.find_job() == nil

    assert random_name()
           |> J.delete()
           |> Alerts.Scheduler.find_job() == nil
  end

  test "Test updating a job" do
    new_function = fn -> :ok2 end

    job =
      random_name()
      |> J.save(fn -> :ok end, "@reboot")
      |> J.update(new_function, "* * * * *")
      |> Alerts.Scheduler.find_job()

    assert job.task == new_function
    assert job.schedule == ~e[* * * * * *]

    assert random_name()
           |> J.save(fn -> :ok end, "@reboot")
           |> J.update(fn -> :ok end, "")
           |> Alerts.Scheduler.find_job() == nil

    assert random_name()
           |> J.save(fn -> :ok end, "@reboot")
           |> J.update(fn -> :ok end, nil)
           |> Alerts.Scheduler.find_job() == nil
  end
end
