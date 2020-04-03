defmodule Business.RepoTest do
  use ExUnit.Case
  alias Alerts.Business.DB.Alert, as: A
  alias Ecto.Changeset, as: C

  defp valid_schedule(schedule) do
    (%A{}
     |> C.cast(%{schedule: schedule}, [:schedule])
     |> A.schedule_is_valid(:schedule)).valid?()
  end

  test "Testing status from results size and alert threshold" do
    assert A.get_status(%{results_size: -1}, %A{}) == "broken"
    assert A.get_status(%{results_size: 0}, %A{}) == "good"
    assert A.get_status(%{results_size: 10}, %A{}) == "bad"
    assert A.get_status(%{results_size: 10}, %A{threshold: 1}) == "bad"
    assert A.get_status(%{results_size: 10}, %A{threshold: 11}) == "under threshold"
  end

  test "Testing scheduler validation" do
    assert valid_schedule("* * * * *") == true
    assert valid_schedule("* */24 * * *") == true
    assert valid_schedule("BADSTUFF") == false
    assert valid_schedule("@reboot") == true
  end
end
