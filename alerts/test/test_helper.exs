ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Alerts.Repo, :auto)

defmodule CustomHelper do
  @bytes "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  @length 32

  def random_name() do
    for _ <- 1..@length do
      :binary.at(@bytes, :rand.uniform(byte_size(@bytes) - 1))
    end
    |> List.to_string()
  end

  def random_atom(), do: random_name() |> String.to_atom()
end
