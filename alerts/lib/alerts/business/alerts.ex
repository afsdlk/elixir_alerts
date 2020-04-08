defmodule Alerts.Business.Alerts do
  alias Alerts.Repo
  alias Alerts.Business.DB
  alias Alerts.Business.Files
  alias Alerts.Business.Odbc
  alias Alerts.Business.Helper, as: H

  require Logger

  def contexts(),
    do: DB.Alert.contexts() |> Repo.all() |> Enum.reduce([], &(&1 ++ &2))

  def alerts_in_context(context, order),
    do: context |> DB.Alert.alerts_in_context(order) |> Repo.all()

  def get!(%DB.Alert{} = alert),
    do: get!(alert.id)

  def get!(alert_id),
    do: DB.Alert |> Repo.get!(alert_id)

  def delete(alert_id),
    do: alert_id |> get!() |> Repo.delete!() |> H.delete_job()

  def change(),
    do: DB.Alert.new_changeset()

  def change(%DB.Alert{} = alert),
    do: DB.Alert.modify_changeset(alert)

  def get_job_name(%DB.Alert{} = alert),
    do: H.get_job_name(alert)

  def create(params) do
    with {:ok, inserted} <- DB.Alert.new_changeset(params) |> Repo.insert() do
      inserted
      |> H.save_job()
      |> Files.create_folder()

      {:ok, inserted}
    else
      other -> other
    end
  end

  def update(%DB.Alert{} = alert, params) do
    with {:ok, updated} <- alert |> DB.Alert.modify_changeset(params) |> Repo.update() do
      updated
      |> H.update_job()
      |> Files.create_folder()

      {:ok, updated}
    else
      other -> other
    end
  end

  def get_all_alert_jobs_config do
    DB.Alert.scheduled_alerts()
    |> Repo.all()
    |> Enum.reduce([], fn alert, acc ->
      case Crontab.CronExpression.Parser.parse(alert.schedule) do
        {:error, text} ->
          Logger.error("Error! #{alert.id} #{alert.schedule} #{text}")
          acc

        _ ->
          acc ++ [H.get_quatum_config(alert)]
      end
    end)
  end

  def run(alert_id) do
    alert = get!(alert_id)
    Files.create_folder(alert)
    alert.query |> Odbc.run_query(alert.repo) |> store_results(alert)
  end

  def get_csv(%{rows: nil}),
    do: nil

  def get_csv(%{columns: columns, rows: rows}) do
    [columns | rows]
    |> CSV.encode()
    |> Enum.to_list()
    |> to_string()
  end

  def get_num_rows(%{rows: nil}), do: -1
  def get_num_rows(%{rows: _rows, num_rows: num_rows}), do: num_rows

  def store_results({:ok, alert_results}, %DB.Alert{} = alert) do
    content_csv = get_csv(alert_results)
    num_rows = get_num_rows(alert_results)

    alert
    |> Files.write(content_csv)

    # @TODO remove results from here, store file name instead
    alert
    |> DB.Alert.run_changeset(%{results: content_csv, results_size: num_rows})
    |> Repo.update!()
  end

  def store_results(_, %DB.Alert{} = alert) do
    alert
    |> DB.Alert.run_changeset(%{results: "", results_size: -1})
    |> Repo.update!()
  end
end
