defmodule Business.JobsTest do
  use ExUnit.Case
  require Alerts.Scheduler
  import Crontab.CronExpression
  alias Alerts.Business.Jobs

  defp random_name() do
    :crypto.strong_rand_bytes(32)
    |> Base.encode64()
    |> binary_part(0, 32)
    |> String.to_atom()
  end

  defmodule(SendingProcess, do: def(run(pid, name), do: send(pid, name)))

  def setup, do: Alerts.Scheduler.delete_all_jobs()

  test "Test empty", do: assert(Alerts.Scheduler.jobs() == [])

  test "Test save" do
    name = random_name()
    pid = self()
    Jobs.save(name, fn -> SendingProcess.run(pid, name) end, "@reboot")

    assert_raise FunctionClauseError, ~r/^.*Quantum.Job.set_name.*$/, fn ->
      Jobs.save("string instead of atom", fn -> :ok end, "@reboot")
    end

    assert_raise RuntimeError, ~r/^Can't parse .* as minute.$/, fn ->
      Jobs.save(:atom, fn -> :ok end, "wrong schedule")
    end

    assert Alerts.Scheduler.find_job(name) !== nil
    assert_receive name
  end

  test "Test delete" do
    name = random_name()
    Jobs.save(name, fn -> :ok end, "@reboot")
    Jobs.delete(name)
    assert Alerts.Scheduler.find_job(name) == nil
  end

  test "Test update" do
    name = random_name()
    fn1 = fn -> :ok end
    fn2 = fn -> :ok end

    Jobs.save(name, fn1, "@reboot")
    Jobs.update(name, fn2, "* * * * *")

    assert_raise RuntimeError, ~r/^Can't parse .* as minute.$/, fn ->
      Jobs.update(:atom, fn1, "wrong schedule")
    end

    # Job exists and function was invoked
    job = Alerts.Scheduler.find_job(name)

    assert job.task == fn2
    assert job.schedule == ~e[* * * * * *]
  end
end
