defmodule Business.JobsTest do
  use ExUnit.Case

  defmodule SendingProcess do
    def run(pid, name) do
      IO.puts("CALLING ELVIS")
      send(pid, name)
    end
  end

  require Alerts.Scheduler
  alias Alerts.Business.Jobs

  setup do
    # Deletes all jobs before running any test
    Alerts.Scheduler.delete_all_jobs()
  end

  defp random_name() do
    :crypto.strong_rand_bytes(32)
    |> Base.encode64()
    |> binary_part(0, 32)
    |> String.to_atom()
  end

  test "Test jobs are empty" do
    assert Alerts.Scheduler.jobs() == []
  end

  test "Saving jobs, errors on save and, callback invocation" do
    name = random_name()
    pid = self()
    Jobs.save(name, fn -> SendingProcess.run(pid, :hello) end, "@reboot")

    # Job exists and function was invoked
    assert Alerts.Scheduler.find_job(name) !== nil
    assert_receive :hello

    assert_raise FunctionClauseError, fn ->
      Jobs.save("string not atom", fn -> SendingProcess.run(self(), name) end, "@reboot")
    end
  end
end
