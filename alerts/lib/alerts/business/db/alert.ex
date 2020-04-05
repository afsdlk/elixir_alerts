defmodule Alerts.Business.DB.Alert do
  use Ecto.Schema

  require Ecto.Query
  require Ecto.Query.API

  alias Ecto.Query, as: Q
  alias Ecto.Changeset, as: C

  require Crontab.CronExpression.Parser

  alias Alerts.Business.Alerts

  @primary_key {:id, :id, autogenerate: true}
  schema "alert" do
    field(:context, :string)
    field(:name, :string)
    field(:query, :string)

    field(:description, :string)

    field(:last_run, :naive_datetime)
    field(:inserted_at, :naive_datetime)
    field(:updated_at, :naive_datetime)

    field(:results, :string)
    field(:results_size, :integer)
    field(:threshold, :integer)

    field(:schedule, :string)

    field(:status, :string)

    field(:repo, :string)

    field(:path, :string)
  end

  defp nowNaive(), do: Timex.now() |> DateTime.truncate(:second) |> Timex.to_naive_datetime()

  def contexts() do
    __MODULE__
    |> Q.select([alert], [alert.context])
    |> Q.distinct(true)
  end

  def scheduled_alerts do
    __MODULE__
    |> Q.where([alert], not is_nil(alert.schedule))
    |> Q.order_by(desc: :name)
  end

  def alerts_in_context(context, order) do
    __MODULE__
    |> Q.where([alert], alert.context == ^context)
    |> Q.order_by(asc: ^order)
  end

  def run_changeset(%__MODULE__{} = alert, params) do
    changeset =
      alert
      |> C.change(last_run: nowNaive())
      |> C.force_change(:results_size, params["results_size"])
      |> C.cast(params, [:results, :results_size])

    changeset
    |> C.change(status: get_status(changeset.changes, changeset.data))
    |> C.validate_required([:last_run])
  end

  def new_changeset(), do: new_changeset(%__MODULE__{}, %{})
  def new_changeset(params), do: new_changeset(%__MODULE__{}, params)

  def new_changeset(%__MODULE__{} = alert, params) do
    alert
    |> C.cast(params, [:name, :description, :context, :query, :schedule, :threshold, :repo, :path])
    |> C.change(inserted_at: nowNaive())
    |> C.change(updated_at: nowNaive())
    |> C.validate_required([:name, :description, :context, :query, :repo])
    |> query_is_valid(:query, repo: Alerts.get_repo(params["repo"]))
    |> C.change(status: get_status(:new))
    |> schedule_is_valid(:schedule)
  end

  def modify_changeset(%__MODULE__{} = alert), do: modify_changeset(alert, %{})

  def modify_changeset(%__MODULE__{} = alert, params) do
    alert
    |> C.cast(params, [:name, :description, :context, :query, :schedule, :threshold, :repo, :path])
    |> C.force_change(:query, params["query"])
    |> C.change(updated_at: nowNaive())
    |> C.validate_required([:name, :description, :context, :query, :repo])
    |> query_is_valid(:query, repo: Alerts.get_repo(params["repo"]))
    |> C.change(status: get_status(:updated))
    |> schedule_is_valid(:schedule)
  end

  def query_is_valid(changeset, field, options \\ []) do
    C.validate_change(changeset, field, fn _, query ->
      case query |> Alerts.run_query(Alerts.get_repo(options[:repo])) do
        {:error, results} -> [{field, "Your query has errors: " <> (results |> Poison.encode!())}]
        _ -> []
      end
    end)
  end

  def schedule_is_valid(changeset, field, _options \\ []) do
    C.validate_change(changeset, field, fn _, schedule ->
      case Crontab.CronExpression.Parser.parse(schedule) do
        {:error, text} -> [{field, "Your scheduler format is wrong: " <> text}]
        _ -> []
      end
    end)
  end

  def get_status(:new), do: "never run"
  def get_status(:updated), do: "never refreshed"
  def get_status(%{results_size: -1}, _), do: "broken"
  def get_status(%{results_size: 0}, _), do: "good"
  def get_status(%{results_size: size}, %__MODULE__{threshold: nil}) when size >= 0, do: "bad"
  def get_status(%{results_size: size}, %__MODULE__{threshold: thr}) when size >= thr, do: "bad"
  def get_status(%{results_size: _size}, %__MODULE__{threshold: _thr}), do: "under threshold"
  def get_status(_c, _a), do: "exception!!!!!!"
end
