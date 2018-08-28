defmodule Manager.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  defmodule PostController do
    use Phoenix.Controller
    def export(conn, _params), do: text(conn, "export posts")
    def index(conn, _params), do: text(conn, "index posts")
    def show(conn, _params), do: text(conn, "show post")
    def edit(conn, _params), do: text(conn, "edit post")
    def new(conn, _params), do: text(conn, "new post")
    def create(conn, _params), do: text(conn, "create post")
    def update(conn, _params), do: text(conn, "update post")
    def delete(conn, _params), do: text(conn, "delete post")
  end

  defmodule Router do
    use Phoenix.Router
    use Manager.Router

    manager_resources("/posts", PostController)
  end

  describe "manager_resources" do
    test "it matches all resource actions" do
      conn = call(Router, :get, "posts")
      assert conn.status == 200
      assert conn.resp_body == "index posts"
    end

    test "it matches export action" do
      conn = call(Router, :get, "posts/export")
      assert conn.status == 200
      assert conn.resp_body == "export posts"
    end

    test "it matches show action with params" do
      conn = call(Router, :get, "posts/123")
      assert conn.status == 200
      assert conn.resp_body == "show post"
      assert conn.params["id"] == "123"
    end

    test "it matches edit action with params" do
      conn = call(Router, :get, "posts/123/edit")
      assert conn.status == 200
      assert conn.resp_body == "edit post"
      assert conn.params["id"] == "123"
    end

    test "it matches new action" do
      conn = call(Router, :get, "posts/new")
      assert conn.status == 200
      assert conn.resp_body == "new post"
    end

    test "it matches create action" do
      conn = call(Router, :post, "posts")
      assert conn.status == 200
      assert conn.resp_body == "create post"
    end

    test "it matches update action" do
      conn = call(Router, :put, "posts/123")
      assert conn.status == 200
      assert conn.resp_body == "update post"
      assert conn.params["id"] == "123"
    end

    test "it matches delete action" do
      conn = call(Router, :delete, "posts/123")
      assert conn.status == 200
      assert conn.resp_body == "delete post"
      assert conn.params["id"] == "123"
    end
  end

  defp call(router, method, path, params \\ nil) do
    method
    |> conn(path, params)
    |> Plug.Conn.fetch_query_params()
    |> router.call(router.init([]))
  end
end
