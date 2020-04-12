defmodule Alerts.Business.Jobs do
  alias Alerts.Scheduler

  def get_quantum_config(job_name, task, schedule) do
    %Quantum.Job{
      name: job_name,
      overlap: false,
      run_strategy: %Quantum.RunStrategy.Random{nodes: :cluster},
      schedule: Crontab.CronExpression.Parser.parse!(schedule),
      state: :active,
      task: task,
      timezone: :utc
    }
  end

  def save(job_name, _task, nil), do: job_name
  def save(job_name, _task, ""), do: job_name

  def save(job_name, task, schedule) do
    :ok =
      Scheduler.new_job()
      |> Quantum.Job.set_name(job_name)
      |> Quantum.Job.set_run_strategy(%Quantum.RunStrategy.Random{nodes: :cluster})
      |> Quantum.Job.set_schedule(Crontab.CronExpression.Parser.parse!(schedule))
      |> Quantum.Job.set_task(task)
      |> Quantum.Job.set_state(:active)
      |> Scheduler.add_job()

    job_name
  end

  def update(job_name, task, schedule) do
    job_name
    |> delete()
    |> save(task, schedule)
  end

  def delete(job_name) do
    :ok = Scheduler.delete_job(job_name)
    job_name
  end
end
