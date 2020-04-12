defmodule Alerts.Business.Odbc do
  require Logger

  @unknown_server [SERVER: 'unknown']
  @could_not_connect "Could not connect to your data source"
  @unknown_error "Unknown error, check your logs"
  @write_query "Write queries are not allowed"

  def get_odbcstring(data_source) do
    (Application.get_env(:alerts, :data_sources)[data_source] || @unknown_server)
    |> Enum.reduce([], fn {k, v}, acc -> acc ++ ["#{k}=#{v}"] end)
    |> Enum.join(";")
    |> String.to_charlist()
  end

  def run_and_rollback(query, db_pid) do
    try do
      results = db_pid |> :odbc.sql_query(query)
      db_pid |> :odbc.commit(:rollback)
      results
    rescue
      _ ->
        db_pid |> :odbc.commit(:rollback)
        @unknown_error
    end
  end

  def connect(odbc_string), do: odbc_string |> :odbc.connect(auto_commit: :off)

  def run_query_odbc_connection_string(query, odbc_string) do
    case connect(odbc_string) do
      {:ok, db_pid} ->
        results = query |> run_and_rollback(db_pid)
        :odbc.disconnect(db_pid)
        results

      _ ->
        {:error, @could_not_connect}
    end
  end

  def run_query(query, source) when is_bitstring(query),
    do: query |> :erlang.binary_to_list() |> run_query(source)

  def run_query(query, source) do
    # @TODO: SEND TO APP STARTUP
    :odbc.start()

    case run_query_odbc_connection_string(query, get_odbcstring(source)) do
      {:selected, c, r} ->
        {:ok, %{columns: c, rows: r} |> process_resultset()}

      {:error, msg} ->
        {:error, msg |> convert_to_string_if_charlist()}

      {:updated, _affected_rows} ->
        {:error, @write_query}

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
      messages: [],
      num_rows: Enum.count(r.rows)
    }
  end
end
