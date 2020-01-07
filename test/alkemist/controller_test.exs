defmodule Alkemist.ControllerTest do
  use Alkemist.ConnCase, async: true
  alias Alkemist.Controller
  import Alkemist.Factory

  defmodule ControllerWithDefaults do
    use Phoenix.Controller
    use TestAlkemist.Alkemist.Controller, resource: TestAlkemist.Post
  end

  defmodule ControllerConfigured do
    use Phoenix.Controller
    use TestAlkemist.Alkemist.Controller, resource: TestAlkemist.Post

    alkemist_config(:index, :index_options)
    alkemist_config(:show, preload: [:category])

    def index_options(_conn) do
      [columns: [:id, :title]]
    end
  end

  defmodule ControllerWithMethods do
    use Phoenix.Controller
    use TestAlkemist.Alkemist.Controller, resource: TestAlkemist.Post

    def columns(_conn), do: [:id, :title]
    def scopes(_conn) do
      [
        {:all, [default: true], fn q -> q end}
      ]
    end
    def rows(_conn, _resource), do: [:id, :title]
    def preload, do: [:category]
  end

  defmodule ControllerWithMethodsAndConfigure do
    use Phoenix.Controller
    use TestAlkemist.Alkemist.Controller, resource: TestAlkemist.Post

    alkemist_config(:index, columns: [:id, :title, :published])

    def columns(_), do: [:id, :title]
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

  describe "not found" do
    test "show returns not found error when non existing id is passed", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        conn
        |> get("/posts/-1")
      end
    end

    test "edit raises not found error when trying to edit non existing resource", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        get(conn, "/posts/-1/edit")
      end
    end
  end

  describe "alkemist_configure" do
    test "it returns empty list by default" do
      assert ControllerWithDefaults.alkemist_config() == []
    end

    test "it accumulates and returns options" do
      assert opts = ControllerConfigured.alkemist_config()
      assert [preload: [:category]] == ControllerConfigured.alkemist_config(:show)

      assert [] == ControllerConfigured.alkemist_config(:edit)
    end
  end

  describe "get_module_opts" do
    @defaults %{phoenix_controller: ControllerConfigured, alkemist_implementation: TestAlkemist.Alkemist, alkemist_resource: TestAlkemist.Post}

    test "it merges configuration from alkemist_config", %{conn: conn} do
      conn =
        conn
        |> Map.put(:private, @defaults)

      assert opts = Controller.get_module_opts(conn, [], :index)
      assert opts[:columns] == [:id, :title]

      post = insert!(:post)

      assert show_opts = Controller.get_module_opts(conn, [], :show, post)
      assert show_opts[:preload] == [:category]
    end

    test "it merges configuration from global methods",  %{conn: conn} do
      conn = Map.put(conn, :private, Map.put(@defaults, :phoenix_controller, ControllerWithMethods))

      assert index_opts = Controller.get_module_opts(conn, [], :index)

      assert index_opts[:preload] == [:category]
      assert index_opts[:columns] == [:id, :title]
      assert length(index_opts[:scopes]) == 1

      assert show_opts = Controller.get_module_opts(conn, [], :show)

      assert show_opts[:preload] == [:category]
      assert show_opts[:rows] == [:id, :title]
    end

    test "it gives alkemist_config a higher prio than default methods", %{conn: conn} do
      conn = Map.put(conn, :private, Map.put(@defaults, :phoenix_controller, ControllerWithMethodsAndConfigure))

      assert opts = Controller.get_module_opts(conn, [], :index)
      assert opts[:columns] == [:id, :title, :published]
    end
  end

  describe "create" do
    @params %{title: "Title", body: "Body", published: true}
    test "it creates a resource", %{conn: conn} do
      conn
      |> post(Routes.post_path(conn, :create), %{post: @params})

      assert post = TestAlkemist.Repo.get_by(TestAlkemist.Post, title: @params.title)
    end

    @tag user: :user
    test "it returns forbidden when not allowed", %{conn: conn} do
      conn = conn
        |> post(Routes.post_path(conn, :create), %{post: @params})

      assert conn.status == 401
    end
  end

  describe "update" do
    @params %{title: "New Title"}
    test "it updates a resource", %{conn: conn} do
      post = insert!(:post)

      conn
      |> put(Routes.post_path(conn, :update, post), %{post: @params})

      assert post = TestAlkemist.Repo.get_by(TestAlkemist.Post, title: @params.title)
    end
  end
end
