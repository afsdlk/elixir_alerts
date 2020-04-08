defmodule Alerts.Business.Files do
  alias Alerts.Business.DB

  @base_folder Application.get_env(:alerts, :export_folder)
  @flags [:write, :utf8]
  @extension ".csv"
  @date_format "{YYYY}{0M}{0D}_{h24}{m}{s}"

  def filename(%DB.Alert{} = a),
    do: a |> filename(Timex.now())

  def filename(%DB.Alert{} = a, :last_run),
    do: a |> filename(a.last_run)

  def filename(%DB.Alert{id: id, name: name}, date) do
    ([
       Slugger.slugify_downcase(name),
       id,
       Mix.env(),
       Timex.format!(date, @date_format)
     ]
     |> Enum.join("-")) <> @extension
  end

  defp fullname(%DB.Alert{} = alert),
    do: "#{basename(alert)}/#{filename(alert)}"

  def basename(path) when is_binary(path),
    do: "#{@base_folder}/#{Slugger.slugify_downcase(path)}"

  def basename(%DB.Alert{} = alert),
    do: basename(alert.context)

  def create_folder(%DB.Alert{} = a),
    do: a |> basename() |> File.mkdir_p!()

  def write(%DB.Alert{} = a, content),
    do: fullname(a) |> File.open!(@flags) |> IO.write(content)
end
