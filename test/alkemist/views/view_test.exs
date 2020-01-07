defmodule Alkemist.ViewTest do
  use Alkemist.ConnCase, async: true

  alias AlkemistView, as: View
  alias TestAlkemist.Alkemist, as: Implementation
  alias TestAlkemist.Post
  doctest View

  setup context do
    conn = context.conn
    |> Plug.Conn.assign(:implementation, Implementation)

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
      resource = %Post{id: 1}
      action = {:edit, [label: "edit"]}
      link = View.member_action(conn, action, resource, [])
      assert Phoenix.HTML.safe_to_string(link) =~ "href=\"/posts/1/edit\""
    end

    test "it handles icon class", %{conn: conn} do
      resource = %Post{id: 1}
      action = {:edit, [label: "edit", icon: "pencil"]}
      link = View.member_action(conn, action, resource, []) |> Phoenix.HTML.safe_to_string()
      assert link =~ "<i class=\"pencil\""
    end
  end

  describe "batch_action_item" do
    test "it creates a batch action from atom", %{conn: conn} do
      action = :batch_action
      assert link = View.batch_action_item(conn, :post, action) |> Phoenix.HTML.safe_to_string()
      assert link =~ "data-action=\"/posts/batch_action\""
    end

    test "it creates batch action with options", %{conn: conn} do
      assert link = View.batch_action_item(conn, :post, {:batch_action, [label: "Custom label"]}) |> Phoenix.HTML.safe_to_string()
      assert link =~ "Custom label"
    end
  end

  describe "collection_action" do
    test "it creates a basic link", %{conn: conn} do
      action = %Alkemist.Types.Action{action: :new, label: "Test", type: :collection}
      link = View.collection_action(conn, action, Post, [])
      assert Phoenix.HTML.safe_to_string(link) =~ "href=\"/posts/new\""
      assert Phoenix.HTML.safe_to_string(link) =~ "Test"
    end

    test "it adds class when link_opts are given", %{conn: conn} do
      action = %Alkemist.Types.Action{type: :collection, action: :new, label: "Test", class: "link"}
      link = View.collection_action(conn, action, Post, [])
      assert Phoenix.HTML.safe_to_string(link) =~ "class=\"link\""
    end
  end

  describe "export_action" do
    test "it generates a link to the export action", %{conn: conn} do
      link = View.export_action(conn, :post) |> Phoenix.HTML.safe_to_string()
      assert link =~ "href=\"/posts?export=true\""
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
      params = [conn, :edit, %Post{id: 1}]
      link = View.action_path(conn, :post, params)
      assert link == "/posts/1/edit"
    end
  end

  describe "scope_link" do
    test "it generates a link to a scope", %{conn: conn} do
      scope = %Alkemist.Types.Scope{key: :published, count: 12, label: "Published", callback: fn q -> q end}
      link = View.scope_link(conn, scope, :post) |> Phoenix.HTML.safe_to_string()
      assert link =~ "?scope=published"
    end

    test "it handles q and s", %{conn: conn} do
      params = %{"s" => "title+asc", "q" => %{"title_ilike" => "test"}}
      conn = Map.put(conn, :params, params)
      scope = %Alkemist.Types.Scope{key: :published, count: 12, label: "Published", callback: fn q -> q end}
      link = View.scope_link(conn, scope, :post) |> Phoenix.HTML.safe_to_string()
      assert link =~ "scope=published"
      assert link =~ "title%2Basc"
      assert link =~ "[title_ilike]=test"
    end

    test "it sets scope class to active when it is marked active", %{conn: conn} do
      scope = scope = %Alkemist.Types.Scope{key: :published, count: 12, label: "Published", callback: fn q -> q end, active?: true}
      link = View.scope_link(conn, scope, :post) |> Phoenix.HTML.safe_to_string()
      assert link =~ "active"
    end
  end

  describe "string_value" do
    test "it renders regular strings" do
      cb = fn r -> Map.get(r, :title) end
      assert elem(View.string_value(cb, %{title: "foo"}, Implementation), 1) == "foo"
    end

    test "it renders true and false" do
      cb = fn r -> Map.get(r, :published) end
      assert elem(View.string_value(cb, %{published: true}, Implementation), 1) =~ "fa-check"

      assert elem(View.string_value(cb, %{published: false}, Implementation), 1) =~ "fa-times"
    end

    test "it renders nil values as empty string" do
      cb = fn r -> Map.get(r, :val) end
      assert View.string_value(cb, %{val: nil}, Implementation) == ""
    end
  end
end
