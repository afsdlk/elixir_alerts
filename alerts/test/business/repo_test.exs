defmodule Business.RepoTest do
  use ExUnit.Case
  alias Alerts.Business.DB.Alert, as: A
  alias Ecto.Changeset, as: C

  defp validate_schedule(schedule) do
    %A{}
    |> C.cast(%{schedule: schedule}, [:schedule])
    |> A.validate(:schedule)
  end

  defp validate_query_postgres(q) do
    %A{}
    |> C.cast(%{query: q}, [:query])
    |> A.validate(:query, repo: Alerts.Repo)
  end

  test "Testing status from results size and alert threshold" do
    assert A.get_status(%{results_size: -1}, %A{}) == "broken"
    assert A.get_status(%{results_size: 0}, %A{}) == "good"
    assert A.get_status(%{results_size: 10}, %A{}) == "bad"
    assert A.get_status(%{results_size: 10}, %A{threshold: 1}) == "bad"
    assert A.get_status(%{results_size: 10}, %A{threshold: 11}) == "under threshold"
  end

  test "Testing scheduler validation" do
    assert validate_schedule("* * * * *").errors == []
    assert validate_schedule("* */24 * * *").errors == []
    assert validate_schedule("@reboot").errors == []
    assert validate_schedule("BADSTUFF").errors !== []
  end

  test "Testing wrong queries postgres" do
    assert validate_query_postgres("<<BAD QUERY>>").errors !== []
    assert validate_query_postgres("DROP DATABASE alerts_test;").errors !== []
    assert validate_query_postgres("SELECT 'A' AS A;").errors == []
  end

  test "Write queries don't affect (rollback)" do
    before_count = A |> Alerts.Repo.all() |> Enum.count()
    assert validate_query_postgres("DELETE FROM alert;").errors == []
    assert A |> Alerts.Repo.all() |> Enum.count() == before_count
  end
end
