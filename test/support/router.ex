defmodule AlkemistTest.Router do
  use Phoenix.Router, helpers: true
  use Alkemist.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/", AlkemistTest do
    pipe_through(:browser)

    get("/dashboard", PlainController, :dashboard, as: :page)
    alkemist_resources("/posts", PostController)
    alkemist_resources("/categories", CategoryController)
    alkemist_resources("/uuid_items", UuidItemController)

    scope "/categories/:category_id" do
      alkemist_resources("/posts", NestedPostController, as: :category_post)
    end
  end
end
