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

  def change(), do: DB.Alert.new_changeset(%DB.Alert{}, %{})
  def change(%DB.Alert{} = alert), do: DB.Alert.modify_changeset(alert, %{})

  def create(params) do
    with {:ok, inserted} <- %DB.Alert{} |> DB.Alert.new_changeset(params) |> Alerts.Repo.insert() do
      save_job(inserted.id, inserted.schedule)
      create_folder(inserted)
      {:ok, inserted}
    else
      other -> other
    end
  end

  def update(%DB.Alert{} = alert, params) do
    with {:ok, updated} <- alert |> DB.Alert.modify_changeset(params) |> Alerts.Repo.update() do
      update_job(updated.id, updated.schedule)
      create_folder(updated)
      {:ok, updated}
    else
      other -> other
    end
  end

  def get_job_name(alert_id), do: "alert_#{alert_id}" |> String.to_atom()

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
                alert.id |> get_job_name(),
                {Alerts.Business.Alerts, :run, [alert.id]},
                alert.schedule
              )
            ]
      end
    end)
  end

  def delete_job(alert_id), do: alert_id |> get_job_name() |> Jobs.delete()

  def delete(alert_id) do
    alert =
      alert_id
      |> get!()
      |> Alerts.Repo.delete!()

    :ok = delete_job(alert_id)

    alert
  end

  def update_job(alert_id, schedule) do
    :ok = delete_job(alert_id)
    :ok = save_job(alert_id, schedule)
  end

  def save_job(_alert_id, nil), do: :ok

  def save_job(alert_id, schedule) do
    task = fn -> run(alert_id) end
    :ok = Jobs.save(alert_id |> get_job_name(), task, schedule)
  end

  def alerts_in_context(context, order) do
    context
    |> DB.Alert.alerts_in_context(order)
    |> Alerts.Repo.all()
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
      case alert_results.rows,
        do:
          (
            nil -> -1
            _ -> alert_results.num_rows
          )

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

  def destination_filename(alert, :use_last_run) do
    alert |> destination_filename(alert.last_run)
  end

  def destination_filename(alert, date) do
    ([
       Slugger.slugify_downcase(alert.name),
       alert.id,
       Mix.env(),
       Timex.format!(date, "{YYYY}{0M}{0D}_{h24}{m}{s}")
     ]
     |> Enum.join("-")) <> ".csv"
  end

  def destination_folder(%DB.Alert{path: nil}), do: nil
  def destination_folder(%DB.Alert{path: ""}), do: nil

  def destination_folder(%DB.Alert{} = alert) do
    "#{Application.get_env(:alerts, :export_folder)}/#{alert.path}"
  end

  def create_folder(alert) do
    case destination_folder(alert) do
      nil ->
        {:ok}

      folder ->
        folder |> File.mkdir_p!()
        {:ok}
    end
  end

  def write_file(%DB.Alert{path: nil}, _), do: nil
  def write_file(%DB.Alert{path: ""}, _), do: nil

  def write_file(%DB.Alert{} = alert, content_csv) do
    (destination_folder(alert) <> "/" <> destination_filename(alert))
    |> File.open!([:write, :utf8])
    |> IO.write(content_csv)
  end
end
