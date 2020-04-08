defmodule Alerts.Business.Helper do
  alias Alerts.Business.DB
  alias Alerts.Business.Jobs

  def get_job_name(%DB.Alert{} = alert),
    do: get_job_name(alert.id)

  def get_job_name(alert_id),
    do: "alert_#{alert_id}" |> String.to_atom()

  defp get_function_definition(%DB.Alert{} = alert),
    do: {Alerts.Business.Alerts, :run, [alert.id]}

  def save_job(%DB.Alert{schedule: nil} = alert, _),
    do: alert

  def save_job(%DB.Alert{schedule: ""} = alert, _),
    do: alert

  def save_job(%DB.Alert{} = alert) do
    alert
    |> get_job_name()
    |> Jobs.save(fn -> Alerts.Business.Alerts.run(alert.id) end, alert.schedule)

    alert
  end

  def get_quatum_config(%DB.Alert{} = alert) do
    Jobs.get_quantum_config(
      get_job_name(alert),
      get_function_definition(alert),
      alert.schedule
    )
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
end
