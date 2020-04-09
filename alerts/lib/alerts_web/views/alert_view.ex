defmodule AlertsWeb.AlertView do
  use AlertsWeb, :view
  require AlertsWeb.Helpers
  alias Alerts.Business.DB

  @alert_hours 4

  def render_date(date) do
    case date do
      nil -> Phoenix.HTML.Tag.content_tag(:em, "never")
      "" -> Phoenix.HTML.Tag.content_tag(:em, "never")
      _ -> date |> AlertsWeb.Helpers.format_date_relative_and_local()
    end
  end

  def render_date_relative(date) do
    case date do
      nil -> Phoenix.HTML.Tag.content_tag(:em, "never")
      "" -> Phoenix.HTML.Tag.content_tag(:em, "never")
      _ -> date |> AlertsWeb.Helpers.format_date_relative()
    end
  end

  def active_tab_class(current, active) do
    if current == active do
      "active"
    else
      ""
    end
  end

  def render_total(total) do
    case total do
      nil -> "-"
      _ -> total
    end
  end

  def render_source(source), do: source

  def render_status(%DB.Alert{status: "broken", last_run: date}) do
    Phoenix.HTML.Tag.content_tag(:span, "broken#{old(date)}", class: "label label-danger")
  end

  def render_status(%DB.Alert{status: "bad", last_run: date}) do
    Phoenix.HTML.Tag.content_tag(:span, "bad#{old(date)}", class: "label label-danger")
  end

  def render_status(%DB.Alert{status: "never run", last_run: date}) do
    Phoenix.HTML.Tag.content_tag(:span, "never run#{old(date)}", class: "label label-info")
  end

  def render_status(%DB.Alert{status: "never refreshed", last_run: date}) do
    Phoenix.HTML.Tag.content_tag(:span, "never refreshed#{old(date)}", class: "label label-info")
  end

  def render_status(%DB.Alert{status: "good", last_run: date}) do
    Phoenix.HTML.Tag.content_tag(:span, "good#{old(date)}", class: "label label-success")
  end

  def render_status(%DB.Alert{status: "under threshold", last_run: date}) do
    Phoenix.HTML.Tag.content_tag(:span, "under threshold#{old(date)}",
      class: "label label-warning"
    )
  end

  def render_status(%DB.Alert{status: unknown, last_run: date}) do
    Phoenix.HTML.Tag.content_tag(:span, "#{unknown}#{old(date)}", class: "label label-danger")
  end

  def old(nil), do: ""

  def old(date) do
    case Timex.diff(Timex.now(), date, :hours) > @alert_hours do
      true -> " (*)"
      false -> ""
    end
  end

  def render_schedule(%DB.Alert{schedule: nil}), do: "manual"

  def render_schedule(%DB.Alert{schedule: schedule}),
    do:
      link(
        schedule,
        to: "https://crontab.guru/#" <> String.replace(schedule, " ", "_"),
        target: "_blank"
      )
end
