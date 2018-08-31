defmodule AlkemistTest.PostController do
  use Phoenix.Controller
  @resource Alkemist.Post
  use Alkemist.Controller

  def index(conn, params) do
    render_index(conn, params, [])
  end

  def show(conn, %{"id" => id}) do
    render_show(conn, id, [])
  end
end
