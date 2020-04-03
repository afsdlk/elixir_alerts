defmodule AlertsWeb.PageControllerTest do
  use AlertsWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Wecome to stored alerts"
  end
end
