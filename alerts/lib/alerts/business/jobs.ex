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

  def delete(job_name), do: :ok = Scheduler.delete_job(job_name)

  def update(job_name, nil), do: :ok = delete(job_name)

  def update(job_name, task, schedule) do
    :ok = delete(job_name)
    :ok = save(job_name, task, schedule)
  end

  def save(_id, nil), do: :ok

  def save(job_name, task, schedule) do
    Scheduler.new_job()
    |> Quantum.Job.set_name(job_name)
    |> Quantum.Job.set_schedule(Crontab.CronExpression.Parser.parse!(schedule))
    |> Quantum.Job.set_task(task)
    |> Scheduler.add_job()
  end
end
