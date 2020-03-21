defmodule AlertsWeb.PageController do
  use AlertsWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
