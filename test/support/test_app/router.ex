defmodule TestAlkemist.Router do
  use TestAlkemist, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", TestAlkemist do
    pipe_through :browser

    get "/posts/batch_action", PostController, :batch_action
    resources "/posts", PostController
    resources "/categories", CategoryController
  end
end
