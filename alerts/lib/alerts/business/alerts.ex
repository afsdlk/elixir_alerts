defmodule Alerts.Business.Alerts do
  require Alerts.Repo
  require Logger

  alias Alerts.Business.DB
  alias Alerts.Business.Jobs

  def contexts do
    DB.Alert.contexts()
    |> Alerts.Repo.all()
    |> Enum.reduce([], fn acc, item -> acc ++ item end)
  end

  def get!(alert_id), do: DB.Alert |> Alerts.Repo.get!(alert_id)

  def delete(alert_id) do
    :ok = alert_id |> get!() |> Alerts.Repo.delete!() |> delete_job()
  end

  def change(), do: DB.Alert.new_changeset(%DB.Alert{}, %{})
  def change(%DB.Alert{} = alert), do: DB.Alert.modify_changeset(alert, %{})

  def create(params) do
    with {:ok, inserted} <- %DB.Alert{} |> DB.Alert.new_changeset(params) |> Alerts.Repo.insert() do
      save_job(inserted)
      create_folder(inserted)
      {:ok, inserted}
    else
      other -> other
    end
  end

  def update(%DB.Alert{} = alert, params) do
    with {:ok, updated} <- alert |> DB.Alert.modify_changeset(params) |> Alerts.Repo.update() do
      update_job(updated)
      create_folder(updated)
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
    |> Alerts.Repo.all()
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

  def save_job(%DB.Alert{schedule: nil}, _), do: :ok
  def save_job(%DB.Alert{schedule: ""}, _), do: :ok

  def save_job(%DB.Alert{} = alert) do
    :ok = alert |> get_job_name() |> Jobs.save(get_function(alert), alert.schedule)
  end

  def update_job(alert) do
    :ok = delete_job(alert)
    :ok = save_job(alert)
  end

  def delete_job(alert), do: alert |> get_job_name() |> Jobs.delete()

  def alerts_in_context(context, order) do
    context |> DB.Alert.alerts_in_context(order) |> Alerts.Repo.all()
  end

  def run_query(query, repo) do
    # @TODO: Non existing repo??
    selected_repo = get_repo(repo) || Alerts.Repo

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

  def get_repo(repo_name) do
    Application.get_env(:alerts, :ecto_repos)
    |> Enum.find(&(&1 == Module.concat([repo_name])))
  end

  def run(alert_id) do
    alert = DB.Alert |> Alerts.Repo.get!(alert_id)
    create_folder(alert)
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

    write_file(alert, content_csv)

    alert
    |> DB.Alert.run_changeset(%{results: content_csv, results_size: num_rows})
    |> Alerts.Repo.update!()
  end

  def store_results(_, alert) do
    alert
    |> DB.Alert.run_changeset(%{results: "", results_size: -1})
    |> Alerts.Repo.update!()
  end

  def destination_filename(alert), do: alert |> destination_filename(Timex.now())
  def destination_filename(alert, :last_run), do: alert |> destination_filename(alert.last_run)

  def destination_filename(alert, date) do
    ([
       Slugger.slugify_downcase(alert.name),
       alert.id,
       Mix.env(),
       Timex.format!(date, "{YYYY}{0M}{0D}_{h24}{m}{s}")
     ]
     |> Enum.join("-")) <> ".csv"
  end

  def destination_folder(%DB.Alert{} = alert) do
    "#{Application.get_env(:alerts, :export_folder)}/#{alert.path}"
  end

  def create_folder(%DB.Alert{path: nil}), do: nil
  def create_folder(%DB.Alert{path: ""}), do: nil

  def create_folder(%DB.Alert{} = alert) do
    alert |> destination_folder() |> File.mkdir_p!()
    {:ok}
  end

  def write_file(%DB.Alert{path: nil}, _), do: nil
  def write_file(%DB.Alert{path: ""}, _), do: nil

  def write_file(%DB.Alert{} = alert, content_csv) do
    (destination_folder(alert) <> "/" <> destination_filename(alert))
    |> File.open!([:write, :utf8])
    |> IO.write(content_csv)
  end
end
