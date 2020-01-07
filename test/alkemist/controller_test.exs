defmodule Alkemist.ControllerTest do
  use Alkemist.ConnCase, async: true
  alias Alkemist.Controller
  import Alkemist.Factory

  defmodule ControllerWithDefaults do
    use Phoenix.Controller
    use TestAlkemist.Alkemist.Controller, resource: TestAlkemist.Post
  end


  describe "default implementation" do
    test "it creates default methods" do
      methods = ControllerWithDefaults.__info__(:functions)

      assert Enum.member?(methods, {:index, 2})
      assert Enum.member?(methods, {:show, 2})
      assert Enum.member?(methods, {:edit, 2})
      assert Enum.member?(methods, {:create, 2})
      assert Enum.member?(methods, {:update, 2})
      assert Enum.member?(methods, {:delete, 2})
      assert Enum.member?(methods, {:forbidden, 1})
    end
  end

  describe "authorization" do
    @describetag user: :user
    test "it prevents user from listing resources", %{conn: conn} do
      conn =
        conn
        |> get(Routes.post_path(conn, :index))

      assert conn.status == 401
    end

    test "it prevents user from viewing a resource", %{conn: conn} do
      post = insert!(:post)
      conn =
        conn
        |> get(Routes.post_path(conn, :show, post))

      assert conn.status == 401
    end

    test "it prevents user from displaying the form", %{conn: conn} do
      conn =
        conn
        |> get(Routes.post_path(conn, :new))

      assert conn.status == 401
    end

    test "it prevents user from displaying the edit form", %{conn: conn} do
      post = insert!(:post)
      conn =
        conn
        |> get(Routes.post_path(conn, :edit, post))

      assert conn.status == 401
    end
  end

end
