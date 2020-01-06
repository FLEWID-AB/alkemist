defmodule TestAlkemist.PostController do
  use TestAlkemist, :controller
  use TestAlkemist.Alkemist.Controller, resource: TestAlkemist.Post

  def batch_action(conn, _params) do
    conn
    |> redirect(to: Routes.post_path(conn, :index))
  end
end
