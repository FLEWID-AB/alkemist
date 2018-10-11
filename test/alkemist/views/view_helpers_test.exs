defmodule Alkemist.ViewHelpersTest do
  use ExUnit.Case, async: true

  alias Alkemist.ViewHelpers

  setup do
    conn = Phoenix.ConnTest.build_conn()
    {:ok, conn: conn}
  end

  test "current_user returns value from authorization provider", %{conn: conn} do
    assert ViewHelpers.current_user(conn) ==
             Alkemist.Config.authorization_provider().current_user(conn)
  end

  test "current_user_name returns value from authorization_provider", %{conn: conn} do
    assert ViewHelpers.current_user_name(conn) ==
             Alkemist.Config.authorization_provider().current_user_name(conn)
  end

  test "resource_action_path returns the path from router helpers", %{conn: conn} do
    assert ViewHelpers.resource_action_path(conn, Alkemist.Post, :index) == "/posts"
  end

  test "resource_action_path returns the path for a single resource", %{conn: conn} do
    post = %Alkemist.Post{id: 1}
    assert ViewHelpers.resource_action_path(conn, post, :show)
  end

  test "any returns if an enum contains items" do
    assert ViewHelpers.any?([1, 2]) == true
    assert ViewHelpers.any?([]) == false
  end

  test "action_link creates a link to a router action", %{conn: conn} do
    link = ViewHelpers.action_link("Posts", conn, :index, Alkemist.Post)
    assert Phoenix.HTML.safe_to_string(link) =~ "href=\"/posts\""
  end

  test "action link accepts wrap to wrap it in a tag", %{conn: conn} do
    link = ViewHelpers.action_link("Posts", conn, :index, Alkemist.Post, wrap: {:li, []})
    assert Phoenix.HTML.safe_to_string(link) =~ "<li><a"
  end

  test "get_default_link_params will automatically populate q, s and scope" do
    params = %{"scope" => "foo", "q" => %{}, "s" => "title+asc", "unused" => "foo"}

    assert %{"scope" => "foo", "s" => "title+asc"} ==
             ViewHelpers.get_default_link_params(%{params: params})
  end

  test "get_default_link_params will not return empty values" do
    params = %{"scope" => "", "q" => %{}, "s" => nil}
    assert %{} == ViewHelpers.get_default_link_params(%{params: params})
  end

  test "right_header_view returns value from config" do
    assert ViewHelpers.right_header_view() ==
             Keyword.get(Alkemist.Config.get(:views), :right_header)
  end

  test "views return value from config" do
    assert ViewHelpers.left_header_view() == Keyword.get(Alkemist.Config.get(:views), :left_header)

    assert ViewHelpers.right_header_view() ==
             Keyword.get(Alkemist.Config.get(:views), :right_header)

    assert ViewHelpers.sidebar_view() == Keyword.get(Alkemist.Config.get(:views), :sidebar)
    assert ViewHelpers.aside_view() == Keyword.get(Alkemist.Config.get(:views), :aside)
  end

  test "site_title returns value from config" do
    assert ViewHelpers.site_title() == Alkemist.Config.get(:title)
  end

  test "menu_items returns value from MenuRegistry" do
    assert ViewHelpers.menu_items() == Alkemist.MenuRegistry.menu_items()
  end
end
