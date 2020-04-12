defmodule Business.RepoTest do
  use ExUnit.Case
  alias Alerts.Business.DB.Alert, as: A
  alias Alerts.Business.Odbc
  alias Ecto.Changeset, as: C

  @default_source "TEST MYSQL"

  defp validate_schedule(schedule) do
    %A{}
    |> C.cast(%{schedule: schedule}, [:schedule])
    |> A.validate(:schedule)
  end

  defp validate_query(q) do
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

  test "wrong queries" do
    assert validate_query("<<BAD QUERY>>").errors !== []
    assert validate_query("DROP DATABASE test;").errors !== []
    assert validate_query("SELECT 'A' AS A;").errors == []
  end

  test "write queries are detected as invalid and do not affect db (rollback or read only)" do
    select = "SELECT * FROM book;"

    delete_query = "DELETE FROM book;"

    {:ok, defore_delete} = Odbc.run_query(select, @default_source)
    assert validate_query(delete_query).errors !== []
    {:ok, after_delete} = Odbc.run_query(select, @default_source)
    assert defore_delete.num_rows == after_delete.num_rows

    insert_query = """
      INSERT INTO book
        (id, title, author, publication_date)
      VALUES
        (10000, 'test', 'test', 20190120);
    """

    {:ok, before_insert} = Odbc.run_query(select, @default_source)
    assert validate_query(insert_query).errors !== []
    {:ok, after_insert} = Odbc.run_query(select, @default_source)
    assert before_insert.num_rows == after_insert.num_rows

    drop_query = "DROP DATABASE test;"

    {:ok, before_drop} = Odbc.run_query(select, @default_source)
    assert validate_query(drop_query).errors !== []
    {:ok, after_drop} = Odbc.run_query(select, @default_source)
    assert before_drop.num_rows == after_drop.num_rows
  end
end
