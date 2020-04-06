ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Alerts.Repo, :auto)

defmodule CustomHelper do
  def random_name() do
    :crypto.strong_rand_bytes(32)
    |> Base.encode64()
    |> binary_part(0, 32)
  end

  def random_atom(), do: random_name() |> String.to_atom()
end
