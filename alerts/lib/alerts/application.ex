defmodule Alerts.Application do
  require Alerts.Scheduler
  import Supervisor.Spec

  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    [
      Alerts.Repo,
      AlertsWeb.Endpoint |> supervisor([]),
      if(System.get_env() != :test, do: Alerts.Scheduler),
      Alerts.VersionSupervisor |> supervisor([])
    ]
    |> Supervisor.start_link(strategy: :one_for_one, name: Alerts.Supervisor)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AlertsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
