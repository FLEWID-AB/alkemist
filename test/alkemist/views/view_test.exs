defmodule Alkemist.ViewTest do
  use ExUnit.Case, async: true

  alias AlkemistView, as: View
  doctest View

  setup do
    conn = Phoenix.ConnTest.build_conn()
    {:ok, conn: conn}
  end

  describe "is_sortable?" do
    test "it returns true when a column is sortable" do
      assert View.is_sortable?({nil, nil, [sortable: true]})
      refute View.is_sortable?({nil, nil, []})
    end
  end

  describe "member_action" do
    test "it creates basic link", %{conn: conn} do
      resource = %Alkemist.Post{id: 1}
      action = {:edit, [label: "edit"]}
      link = View.member_action(conn, action, resource)
      assert Phoenix.HTML.safe_to_string(link) =~ "href=\"/posts/1/edit\""
    end

    test "it handles icon class", %{conn: conn} do
      resource = %Alkemist.Post{id: 1}
      action = {:edit, [label: "edit", icon: "pencil"]}
      link = View.member_action(conn, action, resource) |> Phoenix.HTML.safe_to_string()
      assert link =~ "<i class=\"pencil\""
    end
  end

  describe "batch_action_item" do
    test "it creates a batch action from atom", %{conn: conn} do
      action = :export
      assert link = View.batch_action_item(conn, :post, action) |> Phoenix.HTML.safe_to_string()
      assert link =~ "data-action=\"/posts/export\""
    end

    test "it creates batch action with options", %{conn: conn} do
      assert link = View.batch_action_item(conn, :post, {:export, [label: "Export this"]}) |> Phoenix.HTML.safe_to_string()
      assert link =~ "Export this"
    end
  end

  describe "collection_action" do
    test "it creates a basic link", %{conn: conn} do
      action = {:new, [label: "Test"]}
      link = View.collection_action(conn, action, Alkemist.Post)
      assert Phoenix.HTML.safe_to_string(link) =~ "href=\"/posts/new\""
      assert Phoenix.HTML.safe_to_string(link) =~ "Test"
    end

    test "it adds class when link_opts are given", %{conn: conn} do
      action = {:new, [label: "Test", link_opts: [class: "link"]]}
      link = View.collection_action(conn, action, Alkemist.Post)
      assert Phoenix.HTML.safe_to_string(link) =~ "class=\"link\""
    end

    test "it handles icon class", %{conn: conn} do
      resource = Alkemist.Post
      action = {:new, [label: "new", icon: "pencil"]}
      link = View.collection_action(conn, action, resource) |> Phoenix.HTML.safe_to_string()
      assert link =~ "<i class=\"pencil\""
    end
  end

  describe "export_action" do
    test "it generates a link to the export action", %{conn: conn} do
      link = View.export_action(conn, :post) |> Phoenix.HTML.safe_to_string()
      assert link =~ "href=\"/posts/export\""
    end

    test "it adds all query adn scope params", %{conn: conn} do
      params = %{"scope" => "published", "s" => "title+asc", "q" => %{"title_ilike" => "test"}}
      conn = Map.put(conn, :params, params)
      link = View.export_action(conn, :post) |> Phoenix.HTML.safe_to_string()
      assert link =~ "published"
      assert link =~ "title%2Basc"
      assert link =~ "[title_ilike]=test"
    end
  end

  describe "action_path" do
    test "it generates the path to an action by struct and params", %{conn: conn} do
      params = [conn, :edit, %Alkemist.Post{id: 1}]
      link = View.action_path(:post, params)
      assert link == "/posts/1/edit"
    end
  end

  describe "scope_link" do
    test "it generates a link to a scope", %{conn: conn} do
      scope = {:published, [count: 12, label: "Published"], fn q -> q end}
      link = View.scope_link(conn, scope, :post) |> Phoenix.HTML.safe_to_string()
      assert link =~ "?scope=published"
    end

    test "it handles q and s", %{conn: conn} do
      params = %{"s" => "title+asc", "q" => %{"title_ilike" => "test"}}
      conn = Map.put(conn, :params, params)
      scope = {:published, [count: 12, label: "Published"], fn q -> q end}
      link = View.scope_link(conn, scope, :post) |> Phoenix.HTML.safe_to_string()
      assert link =~ "scope=published"
      assert link =~ "title%2Basc"
      assert link =~ "[title_ilike]=test"
    end
  end

  describe "string_value" do
    test "it renders regular strings" do
      cb = fn r -> Map.get(r, :title) end
      assert elem(View.string_value(cb, %{title: "foo"}), 1) == "foo"
    end

    test "it renders true and false" do
      cb = fn r -> Map.get(r, :published) end
      assert elem(View.string_value(cb, %{published: true}), 1) =~ "fa-check"

      assert elem(View.string_value(cb, %{published: false}), 1) =~ "fa-times"
    end

    test "it renders nil values as empty string" do
      cb = fn r -> Map.get(r, :val) end
      assert View.string_value(cb, %{val: nil}) == ""
    end
  end
end
