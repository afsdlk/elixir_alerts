defmodule Alerts.Business.Odbc do
  require Logger

  defp get_odbcstring(_repo) do
    'Driver=MySQL ANSI;Server=mysql;Trusted_Connection=False;Database=lala;UID=root;PWD=mysql;initstmt=SET GLOBAL read_only = 1;SET GLOBAL super_read_only = 1'
    # SET SESSION CHARACTERISTICS AS TRANSACTION READ ONLY;
    # 'Driver={PostgreSQL Unicode};Server=alerts_db;Database=alerts_dev;UID=postgres;PWD=postgres;'
  end

  def run_query(query, repo) when is_bitstring(query),
    do: query |> :erlang.binary_to_list() |> run_query(repo)

  def run_query(query, repo) do
    # @TODO: SEND TO APP STARTUP
    :odbc.start()

    {:ok, db_pid} = repo |> get_odbcstring() |> :odbc.connect(auto_commit: :off)

    results =
      try do
        db_pid |> :odbc.sql_query(query)
      rescue
        _ ->
          "Unknown error, check your logs"
      end

    :odbc.commit(db_pid, :rollback)
    :odbc.disconnect(db_pid)

    case results do
      {:selected, c, r} ->
        {:ok, %{columns: c, rows: r, pid: db_pid} |> process_resultset()}

      {:error, msg} ->
        {:error, msg |> convert_to_string_if_charlist()}

      {:updated, _affected_rows} ->
        {:error, "Write queries are not allowed"}

      # weird case, does this even happen?
      other ->
        {:error, other}
    end
  end

  def convert_to_string_if_charlist(item) when is_list(item), do: :erlang.list_to_binary(item)
  def convert_to_string_if_charlist(item), do: item

  @doc """

  iex(5)> Alerts.Business.Odbc.process_rows([{'a', 1}, {:atom, 1.2}])
  [["a", 1], [:atom, 1.2]]

  """
  def process_rows(map) do
    map
    |> Enum.map(
      &(&1
        |> Tuple.to_list()
        |> Enum.map(fn item -> convert_to_string_if_charlist(item) end))
    )
  end

  @doc """

  iex> Alerts.Business.Odbc.process_columns(['a', 1, :atom, 1.2])
  ["a", 1, :atom, 1.2]

  """
  def process_columns(list) do
    list |> Enum.map(&convert_to_string_if_charlist(&1))
  end

  def process_resultset(r) do
    %{
      columns: process_columns(r.columns),
      rows: process_rows(r.rows),
      command: :select,
      connection_id: r.pid,
      messages: [],
      num_rows: Enum.count(r.rows)
    }
  end
end
