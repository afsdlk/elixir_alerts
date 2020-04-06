defmodule Business.LibTest do
  use ExUnit.Case
  alias Alerts.Business.Alerts, as: Lib

  test "create alert in db" do
    {:ok, inserted} =
      %{
        name: CustomHelper.random_name(),
        context: "test",
        query: "SELECT 'a' AS a;",
        description: "test",
        repo: "test"
      }
      |> Lib.create()

    assert Lib.get!(inserted.id) !== nil
  end
end
