defmodule AlertsWeb.Router do
  use AlertsWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", AlertsWeb do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", PageController, :index)

    get("/alerts", AlertController, :index)
    get("/alerts/new", AlertController, :new)
    post("/alerts/reboot", AlertController, :reboot)

    post("/alerts", AlertController, :create)
    get("/alerts/edit/:id", AlertController, :edit)
    put("/alerts/:id", AlertController, :update)
    delete("/alerts/:id", AlertController, :delete)
    get("/alerts/:id", AlertController, :view)
    get("/alerts/run/:id", AlertController, :index)
    get("/alerts/csv/:id", AlertController, :index)
    post("/alerts/run/:id", AlertController, :run)
    post("/alerts/csv/:id", AlertController, :csv)
  end

  # Other scopes may use custom stacks.
  # scope "/api", AlertsWeb do
  #   pipe_through :api
  # end
end
