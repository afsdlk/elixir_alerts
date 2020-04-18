defmodule Alerts.VersionSupervisor do
  use DynamicSupervisor

  def start_link() do
    __MODULE__
    |> DynamicSupervisor.start_link([], name: :AlertsVersionSupervisor)
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_child(context) do
    :AlertsVersionSupervisor
    |> Process.whereis()
    |> DynamicSupervisor.start_child({Alerts.Version, [context]})
    |> case do
      {:error, {:already_started, pid}} -> pid
      {:ok, pid} -> pid
      _ -> nil
    end
  end
end
