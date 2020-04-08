defmodule Alerts.Scheduler do
  use Quantum.Scheduler, otp_app: :alerts
  require Logger

  @environmet_blacklist [:test]

  def init(opts) do
    case Enum.member?(@environmet_blacklist, Mix.env()) or IEx.started?() do
      true ->
        IO.inspect(opts)
        opts

      false ->
        delete_all_jobs()
        opts_with_jobs = get_startup_config(opts)
        opts_with_jobs |> IO.inspect()
        opts_with_jobs
    end
  end

  def get_startup_config(opts) do
    job_definition = Alerts.Business.Alerts.get_all_alert_jobs_config()
    (opts |> List.delete(List.keyfind(opts, :jobs, 0))) ++ [jobs: job_definition]
  end

  def reboot_all_jobs() do
    Alerts.Business.Alerts.reboot_all_jobs()
    jobs() |> IO.inspect()
  end
end
