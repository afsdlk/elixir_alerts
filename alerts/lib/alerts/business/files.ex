defmodule Alerts.Business.Files do
  alias Alerts.Business.DB

  @base_folder Application.get_env(:alerts, :export_folder)
  @flags [:write, :utf8]
  @extension ".csv"
  @date_format "{YYYY}{0M}{0D}_{h24}{m}{s}"

  def filename(%DB.Alert{} = a, :last_run),
    do: filename(a.id, a.name, Timex.format!(a.last_run, @date_format))

  def filename(id, name) do
    ([id, Slugger.slugify_downcase(name), Mix.env()] |> Enum.join("-")) <> @extension
  end

  def filename(id, name, extra) do
    ([id, Slugger.slugify_downcase(name), Mix.env(), extra] |> Enum.join("-")) <> @extension
  end

  def fullname(%DB.Alert{} = alert),
    do: fullname(alert.context, alert.name, alert.id)

  def fullname(context, name, id),
    do: "#{dirname(context)}/#{filename(id, name)}"

  def dirname(path),
    do: "#{@base_folder}/#{Slugger.slugify_downcase(path)}"

  def create_folder(%DB.Alert{} = a),
    do: a.context |> dirname() |> File.mkdir_p!()

  def write(%DB.Alert{} = a, content),
    do: fullname(a) |> File.open!(@flags) |> IO.write(content)
end
