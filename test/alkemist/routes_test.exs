defmodule Alkemist.RoutesTest do
  use ExUnit.Case, async: true

  alias Alkemist.Routes
  alias AlkemistTest.{CategoryController, NestedPostController, PostController, Router}

  defp conn(path \\ "/") do
    Phoenix.ConnTest.build_conn(:get, path)
    |> Plug.Conn.put_private(:phoenix_router, Router)
  end

  test "builds paths for every resource action" do
    c = conn()
    assert Routes.path(c, PostController, :index) == "/posts"
    assert Routes.path(c, PostController, :new) == "/posts/new"
    assert Routes.path(c, PostController, :export) == "/posts/export"
    assert Routes.path(c, PostController, :show, [%Alkemist.Post{id: 7}]) == "/posts/7"
    assert Routes.path(c, PostController, :edit, ["7"]) == "/posts/7/edit"

    assert Routes.path(c, PostController, :index, [], %{
             "page" => 2,
             "q" => %{"title_cont" => "a b"}
           }) ==
             "/posts?page=2&q[title_cont]=a+b"
  end

  test "fills nested route params in order" do
    assert Routes.path(conn(), NestedPostController, :show, [
             %Alkemist.Category{id: 3},
             %Alkemist.Post{id: 9}
           ]) ==
             "/categories/3/posts/9"

    assert Routes.path(conn(), NestedPostController, :index, [3]) == "/categories/3/posts"
  end

  test "respects the endpoint script name" do
    c = %{conn() | script_name: ["admin"]}
    assert Routes.path(c, CategoryController, :index) == "/admin/categories"
  end

  test "encodes params with Phoenix.Param and URI rules" do
    assert Routes.path(conn(), PostController, :show, ["a b/c"]) == "/posts/a%20b%2Fc"
  end

  test "raises for missing routes and wrong param counts" do
    assert_raise Alkemist.RouteError, ~r/no route for AlkemistTest.PlainController :index/, fn ->
      Routes.path(conn(), AlkemistTest.PlainController, :index)
    end

    assert_raise ArgumentError, ~r/missing value for :id/, fn ->
      Routes.path(conn(), PostController, :show)
    end

    assert_raise ArgumentError, ~r/too many route params/, fn ->
      Routes.path(conn(), PostController, :index, [1])
    end
  end

  test "path_for/4 on the controller takes over" do
    defmodule CustomPathController do
      def path_for(_conn, action, params, _query),
        do: "/custom/#{action}/#{Enum.join(params, "-")}"
    end

    assert Routes.path(conn(), CustomPathController, :show, [1, 2]) == "/custom/show/1-2"
  end

  test "controller_for/2 finds the Alkemist controller for a schema" do
    assert Routes.controller_for(Router, Alkemist.Category) == CategoryController
    assert Routes.controller_for(conn(), Alkemist.UuidItem) == AlkemistTest.UuidItemController
    assert Routes.controller_for(Router, Alkemist.Tag) == nil
  end

  test "route?/3" do
    assert Routes.route?(Router, PostController, :export)
    refute Routes.route?(Router, AlkemistTest.PlainController, :index)
  end

  test "a conn outside a router raises a clear error" do
    assert_raise ArgumentError, ~r/no :phoenix_router/, fn ->
      Routes.path(Phoenix.ConnTest.build_conn(), PostController, :index)
    end
  end
end
