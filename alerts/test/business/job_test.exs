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

  test "Test save" do
    name = random_name()
    pid = self()
    J.save(name, fn -> SendingProcess.run(pid, name) end, "@reboot")

    assert_raise FunctionClauseError, ~r/^.*Quantum.Job.set_name.*$/, fn ->
      J.save("string instead of atom", fn -> :ok end, "@reboot")
    end

    assert_raise RuntimeError, ~r/^Can't parse .* as minute.$/, fn ->
      J.save(:atom, fn -> :ok end, "wrong schedule")
    end

    assert Alerts.Scheduler.find_job(name) !== nil
    assert_receive name, 1_000
  end

  test "Test delete" do
    name = random_name()
    J.save(name, fn -> :ok end, "@reboot")
    J.delete(name)
    assert Alerts.Scheduler.find_job(name) == nil
  end

  test "Test update" do
    name = random_name()
    fn1 = fn -> :ok end
    fn2 = fn -> :ok end

    J.save(name, fn1, "@reboot")
    J.update(name, fn2, "* * * * *")

    assert_raise RuntimeError, ~r/^Can't parse .* as minute.$/, fn ->
      J.update(:atom, fn1, "wrong schedule")
    end

    # Job exists and function was invoked
    job = Alerts.Scheduler.find_job(name)

    assert job.task == fn2
    assert job.schedule == ~e[* * * * * *]
  end
end
