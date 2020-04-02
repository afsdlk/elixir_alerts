defmodule Alerts.Scheduler do
  use Quantum.Scheduler, otp_app: :alerts
  @environmet_blacklist [:test]

  def init(opts) do
    case Enum.member?(@environmet_blacklist, Mix.env()) or IEx.started?() do
      true ->
        IO.inspect(opts)
        opts

      false ->
        delete_all_jobs()

        opts_with_jobs =
          List.delete(opts, List.keyfind(opts, :jobs, 0)) ++
            [jobs: Alerts.Business.Alerts.get_all_alert_jobs_config()]

        IO.inspect(opts_with_jobs)
        opts_with_jobs
    end
  end
end
