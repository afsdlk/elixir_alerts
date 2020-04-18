defmodule Alerts.Version do
  use GenServer

  defp get_init_command(folder),
    do: '''
      cd #{folder} \
      && git init
    '''

  defp get_commit_command(folder, fullname),
    do: '''
      cd #{folder} \
      && git add #{fullname} \
      && git commit -m "scheduled execution" #{fullname}
    '''

  def init(init_arg),
    do: {:ok, init_arg}

  def get_or_create_supervised_server(context),
    do: Alerts.VersionSupervisor.add_child(context)

  def start_link(context),
    do: __MODULE__ |> GenServer.start_link(nil, name: {:global, "AlertsVersion #{context}"})

  def handle_cast({folder}, state) do
    folder
    |> get_init_command()
    |> :os.cmd()
    |> List.to_string()
    |> String.split(~r{\n}, trim: true)
    |> IO.inspect()

    {:noreply, state}
  end

  def handle_cast({folder, file}, state) do
    folder
    |> get_commit_command(file)
    |> :os.cmd()
    |> List.to_string()
    |> String.split(~r{\n}, trim: true)
    |> IO.inspect()

    {:noreply, state}
  end
end
