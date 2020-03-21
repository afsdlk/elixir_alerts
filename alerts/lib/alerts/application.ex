defmodule Alerts.Application do
  require Alerts.Scheduler
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Start the Ecto repositories
    repos = Application.get_env(:alerts, :ecto_repos) |> Enum.map(&supervisor(&1, []))

    # Define workers and child supervisors to be supervised
    children =
      repos ++
        [
          # Start the endpoint when the application starts
          supervisor(AlertsWeb.Endpoint, []),
          # Start your own worker by calling: Alerts.Worker.start_link(arg1, arg2, arg3)
          # worker(Alerts.Worker, [arg1, arg2, arg3]),
          if System.get_env() != :test do
            Alerts.Scheduler
          end
        ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Alerts.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AlertsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
