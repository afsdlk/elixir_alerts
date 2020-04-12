defmodule Business.RepoTest do
  use ExUnit.Case
  alias Alerts.Repo
  alias Alerts.Business.DB.Alert, as: A
  alias Ecto.Changeset, as: C

  @default_source "MYSQL TEST"

  defp validate_schedule(schedule) do
    %A{}
    |> C.cast(%{schedule: schedule}, [:schedule])
    |> A.validate(:schedule)
  end

  defp validate_query_postgres(q) do
    %A{}
    |> C.cast(%{query: q}, [:query])
    |> A.validate(:query, source: @default_source)
  end

  test "calculating status from results size and alert threshold" do
    assert A.get_status(%{results_size: -1}) == "broken"
    assert A.get_status(%{results_size: 0}) == "good"
    assert A.get_status(%{results_size: 10}) == "bad"
    assert A.get_status(%{results_size: 10, threshold: 1}) == "bad"
    assert A.get_status(%{results_size: 10, threshold: 11}) == "under threshold"
  end

  test "cron scheduler validation" do
    assert validate_schedule("* * * * *").errors == []
    assert validate_schedule("* */24 * * *").errors == []
    assert validate_schedule("@reboot").errors == []
    assert validate_schedule("BADSTUFF").errors !== []
  end

  test "wrong queries (postgres)" do
    assert validate_query_postgres("<<BAD QUERY>>").errors !== []
    assert validate_query_postgres("DROP DATABASE alerts_test;").errors !== []
    assert validate_query_postgres("SELECT 'A' AS A;").errors == []
  end

  test "write queries fail with error and do not affect db (rollback)" do
    delete_query = "DELETE FROM alert;"

    with before_count <- A |> Repo.all() |> Enum.count() do
      assert validate_query_postgres(delete_query).errors !== []
      assert A |> Repo.all() |> Enum.count() == before_count
    end

    insert_query = """
      INSERT INTO book
        (id, title, author, publication_date)
      VALUES
        (10000, 'test', 'test', 20190120);
    """

    with before_count <- A |> Repo.all() |> Enum.count() do
      assert validate_query_postgres(insert_query).errors !== []
      assert A |> Repo.all() |> Enum.count() == before_count
    end
  end
end
