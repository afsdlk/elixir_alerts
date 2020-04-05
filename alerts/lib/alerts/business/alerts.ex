defmodule Alerts.Business.Alerts do
  alias Alerts.Repo
  alias Alerts.Business.DB
  alias Alerts.Business.Jobs
  alias Alerts.Business.Files

  def contexts(),
    do: DB.Alert.contexts() |> Repo.all() |> Enum.reduce([], &(&1 ++ &2))

  def alerts_in_context(context, order),
    do: context |> DB.Alert.alerts_in_context(order) |> Repo.all()

  def get!(alert_id),
    do: DB.Alert |> Repo.get!(alert_id)

  def delete(alert_id),
    do: :ok = alert_id |> get!() |> Repo.delete!() |> delete_job()

  def change(), do: DB.Alert.new_changeset()
  def change(%DB.Alert{} = alert), do: DB.Alert.modify_changeset(alert)

  def create(params) do
    with {:ok, inserted} <- DB.Alert.new_changeset(params) |> Repo.insert() do
      inserted
      |> save_job()
      |> Files.create_folder()

      {:ok, inserted}
    else
      other -> other
    end
  end

  def update(%DB.Alert{} = alert, params) do
    with {:ok, updated} <- alert |> DB.Alert.modify_changeset(params) |> Repo.update() do
      updated
      |> update_job()
      |> Files.create_folder()

      {:ok, updated}
    else
      other -> other
    end
  end

  defp get_job_name(%DB.Alert{} = alert), do: get_job_name(alert.id)
  defp get_job_name(alert_id), do: "alert_#{alert_id}" |> String.to_atom()

  defp get_function(%DB.Alert{} = alert, :definition), do: {__MODULE__, :run, [alert.id]}
  defp get_function(%DB.Alert{} = alert), do: fn -> run(alert.id) end

  def get_all_alert_jobs_config do
    DB.Alert.scheduled_alerts()
    |> Repo.all()
    |> Enum.reduce([], fn alert, acc ->
      case Crontab.CronExpression.Parser.parse(alert.schedule) do
        {:error, text} ->
          IO.inspect("Error! #{alert.id} #{alert.schedule} #{text}")
          acc

        _ ->
          acc ++
            [
              Jobs.get_quantum_config(
                get_job_name(alert),
                get_function(alert, :definition),
                alert.schedule
              )
            ]
      end
    end)
  end

  def save_job(%DB.Alert{schedule: nil} = alert, _), do: alert
  def save_job(%DB.Alert{schedule: ""} = alert, _), do: alert

  def save_job(%DB.Alert{} = alert) do
    alert
    |> get_job_name()
    |> Jobs.save(get_function(alert), alert.schedule)

    alert
  end

  def update_job(alert) do
    alert
    |> delete_job()
    |> save_job()

    alert
  end

  def delete_job(alert) do
    alert
    |> get_job_name()
    |> Jobs.delete()

    alert
  end

  def run_query(query, repo) do
    # @TODO: Non existing repo??
    selected_repo = get_repo(repo)

    # rollback returs always :error
    {_, transaction_results} =
      selected_repo.transaction(fn ->
        case selected_repo |> Ecto.Adapters.SQL.query(query, [], timeout: 1_000) do
          # Protection against write queries inmediately rollback if the query is correct
          {:ok, results} ->
            selected_repo.rollback({:ok, results})

          {:error, results} ->
            selected_repo.rollback({:error, results})

          other ->
            selected_repo.rollback({:error, other})
        end
      end)

    transaction_results
  end

  def get_repo(), do: Alerts.Repo

  def get_repo(repo_name) do
    Application.get_env(:alerts, :ecto_repos)
    |> Enum.find(&(&1 == Module.concat([repo_name])))
  end

  def run(alert_id) do
    alert = get!(alert_id)
    Files.create_folder(alert)
    run_query(alert.query, alert.repo) |> store_results(alert)
  end

  def store_results({:ok, alert_results}, alert) do
    # "pirate" write queries create weird results, we want the query to store nil results
    content_csv =
      case alert_results.rows do
        nil ->
          nil

        _ ->
          # This thing crashes with naive_datetime like inserted_at, updated_at,
          # the solution is to use updated_at::TEXT in your query
          [alert_results.columns | alert_results.rows]
          |> CSV.encode()
          |> Enum.to_list()
          |> to_string()
      end

    num_rows =
      case alert_results.rows do
        nil -> -1
        _ -> alert_results.num_rows
      end

    Files.write(alert, content_csv)

    alert
    |> DB.Alert.run_changeset(%{results: content_csv, results_size: num_rows})
    |> Repo.update!()
  end

  def store_results(_, alert) do
    alert
    |> DB.Alert.run_changeset(%{results: "", results_size: -1})
    |> Repo.update!()
  end
end
