defmodule AlertsWeb.AlertController do
  use AlertsWeb, :controller

  alias Alerts.Business.Files
  alias Alerts.Business.Alerts

  def index(conn, params) do
    available_contexts = Alerts.contexts()
    context = params["context"] || Enum.at(available_contexts, 0) || ""
    alerts = Alerts.alerts_in_context(context, String.to_atom(params["order"] || "name"))

    render(
      conn,
      "index.html",
      available_contexts: (available_contexts ++ [context]) |> Enum.uniq(),
      context: context,
      alerts: alerts
    )
  end

  def view(conn, %{"id" => alert_id}), do: render(conn, "view.html", alert: Alerts.get!(alert_id))

  def new(conn, _params), do: render(conn, "new.html", alert_changeset: Alerts.change())

  def create(conn, %{"alert" => params}) do
    Alerts.create(params)
    |> case do
      {:ok, alert} ->
        conn
        |> put_flash(:info, "ok")
        |> redirect(to: alert_path(conn, :view, alert.id))

      {:error, %Ecto.Changeset{} = alert_changeset} ->
        render(conn, "new.html", alert_changeset: alert_changeset)
    end
  end

  def edit(conn, %{"id" => alert_id}) do
    alert = Alerts.get!(alert_id)
    render(conn, "edit.html", alert: alert, alert_changeset: Alerts.change(alert))
  end

  def update(conn, %{"alert" => params, "id" => alert_id}) do
    alert = Alerts.get!(alert_id)

    Alerts.update(alert, params)
    |> case do
      {:ok, alert} ->
        conn
        |> put_flash(:info, "ok")
        |> redirect(to: alert_path(conn, :view, alert.id))

      {:error, %Ecto.Changeset{} = alert_changeset} ->
        render(conn, "edit.html", alert_changeset: alert_changeset, alert: alert)
    end
  end

  def delete(conn, %{"id" => alert_id}) do
    alert = Alerts.delete(alert_id)

    conn
    |> put_flash(:info, "Alert deleted successfully.")
    |> redirect(to: alert_path(conn, :index, %{context: alert.context}))
  end

  def run(conn, params = %{"id" => alert_id}) do
    alert = Alerts.run(alert_id)

    {level, msg} =
      case alert.results_size do
        -1 ->
          {:error, ["Alert ", Phoenix.HTML.Tag.content_tag(:strong, alert.name), " is broken"]}

        _ ->
          {:info,
           ["Alert ", Phoenix.HTML.Tag.content_tag(:strong, alert.name), " run succesfully"]}
      end

    case params["follow"] do
      nil ->
        conn
        |> put_flash(level, msg)
        |> redirect(to: alert_path(conn, :index, %{context: alert.context}))

      _ ->
        conn
        |> put_flash(level, msg)
        |> redirect(to: alert_path(conn, :view, alert.id))
    end
  end

  def csv(conn, %{"id" => alert_id}) do
    alert = Alerts.get!(alert_id)
    filename = Files.filename(alert, :last_run)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
    |> send_resp(200, alert.results)
  end
end
