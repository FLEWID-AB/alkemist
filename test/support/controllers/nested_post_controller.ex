defmodule AlkemistTest.NestedPostController do
  @moduledoc "Fixture controller mounted under /categories/:category_id to exercise route_params."
  use Phoenix.Controller, formats: [:html]
  @resource Alkemist.Post
  use Alkemist.Controller

  menu(false)

  def index(conn, %{"category_id" => category_id} = params) do
    render_index(conn, params, route_params: [category_id])
  end

  def show(conn, %{"id" => id, "category_id" => category_id}) do
    render_show(conn, id, route_params: [category_id])
  end
end
