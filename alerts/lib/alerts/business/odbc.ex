defmodule Alerts.Business.Odbc do
  require Logger

  defp get_odbcstring(_repo) do
    'Driver={PostgreSQL Unicode};Server=alerts_db;Database=alerts_dev;Trusted_Connection=False;UID=postgres;PWD=postgres;'
  end

  def run_query(query, repo) when is_bitstring(query) do
    query |> :erlang.binary_to_list() |> run_query(repo)
  end

  def run_query(query, repo) do
    # @TODO: SEND TO APP STARTUP
    :odbc.start()

    {:ok, db_pid} = repo |> get_odbcstring() |> :odbc.connect(auto_commit: :off)
    results = db_pid |> :odbc.sql_query(query)
    :odbc.commit(db_pid, :rollback)
    :odbc.disconnect(db_pid)

    case results do
      {:selected, columns, rows} ->
        {:ok, %{rows: rows, columns: columns} |> process_resultset(db_pid)}

      {:error, msg} ->
        {:error, msg |> convert_to_string_if_charlist()}

      {:updated, _affected_rows} ->
        {:error, "Write queries are not allowed"}

      # weird case, does this even happen?
      other ->
        Logger.error(other)
        {:error, "Unknown error, check your logs"}
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

  def process_resultset(r, pid) do
    %{
      columns: process_columns(r.columns),
      rows: process_rows(r.rows),
      command: :select,
      connection_id: pid,
      messages: [],
      num_rows: Enum.count(r.rows)
    }
  end
end
