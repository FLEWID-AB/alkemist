defmodule Alkemist.ControllerTest do
  use Alkemist.ConnCase, async: false

  defmodule DenyExport do
    use Alkemist.Authorization
    @impl true
    def authorize_action(_resource, _conn, action), do: action != :export
  end

  defmodule DenyAll do
    use Alkemist.Authorization
    @impl true
    def authorize_action(_, _, _), do: false
  end

  defp with_provider(provider, fun) do
    config = Application.get_env(:alkemist, Alkemist, [])

    Application.put_env(
      :alkemist,
      Alkemist,
      Keyword.put(config, :authorization_provider, provider)
    )

    Alkemist.Config.reset(:alkemist)

    try do
      fun.()
    after
      Application.put_env(:alkemist, Alkemist, config)
      Alkemist.Config.reset(:alkemist)
    end
  end

  describe "index" do
    test "renders the table with filters, sorting and pagination", %{conn: conn} do
      insert_category!(name: "Alpha")
      insert_category!(name: "Beta")

      html =
        conn
        |> get("/categories", %{"q" => %{"name_cont" => "alph"}, "s" => "name+asc"})
        |> html_response(200)

      assert html =~ "Alpha"
      refute html =~ ">Beta<"
      assert html =~ ~s(href="/categories/export)
    end

    test "unknown filters are ignored", %{conn: conn} do
      insert_category!(name: "Alpha")

      assert conn |> get("/categories", %{"q" => %{"bogus_eq" => "1"}}) |> html_response(200) =~
               "Alpha"
    end
  end

  describe "show / edit / not found" do
    test "show and edit render the record", %{conn: conn} do
      c = insert_category!(name: "Gamma")
      assert conn |> get("/categories/#{c.id}") |> html_response(200) =~ "Gamma"
      assert conn |> get("/categories/#{c.id}/edit") |> html_response(200) =~ "Gamma"
    end

    test "unknown and malformed ids give 404 instead of raising", %{conn: conn} do
      assert conn |> get("/categories/999999") |> html_response(404) =~ "Not Found"
      assert conn |> get("/categories/not-a-number") |> html_response(404)
      assert conn |> get("/categories/not-a-number/edit") |> html_response(404)
      assert conn |> delete("/categories/abc") |> html_response(404)
    end

    test "binary_id primary keys load and reject malformed ids", %{conn: conn} do
      item = Repo.insert!(%Alkemist.UuidItem{name: "Widget"})
      assert conn |> get("/uuid_items/#{item.id}") |> html_response(200) =~ "Widget"
      assert conn |> get("/uuid_items/not-a-uuid") |> html_response(404)
    end
  end

  describe "create / update / delete" do
    test "create redirects to show and update to show, using router-derived paths", %{conn: conn} do
      conn = post(conn, "/categories", %{"category" => %{"name" => "Fresh"}})
      assert %{id: id} = Repo.get_by!(Alkemist.Category, name: "Fresh")
      assert redirected_to(conn) == "/categories/#{id}"

      conn = put(build_conn(), "/categories/#{id}", %{"category" => %{"name" => "Renamed"}})
      assert redirected_to(conn) == "/categories/#{id}"
      assert Repo.get!(Alkemist.Category, id).name == "Renamed"

      conn = delete(build_conn(), "/categories/#{id}")
      assert redirected_to(conn) == "/categories"
      refute Repo.get(Alkemist.Category, id)
    end

    test "new renders the component form posting to create", %{conn: conn} do
      html = conn |> get("/categories/new") |> html_response(200)
      assert html =~ ~s(name="category[name]")
      assert html =~ ~r/<form [^>]*action="\/categories"[^>]*method="post"/
      assert html =~ ~s(id="category-form")
      assert html =~ "New Category"
    end

    test "edit renders the form with the current values and a put method", %{conn: conn} do
      c = insert_category!(name: "Editable")
      html = conn |> get("/categories/#{c.id}/edit") |> html_response(200)
      assert html =~ ~s(value="Editable")
      assert html =~ ~r/<form [^>]*action="\/categories\/#{c.id}"/
      assert html =~ ~s(name="_method" type="hidden" hidden value="put")
    end

    test "invalid input re-renders the form with errors", %{conn: conn} do
      conn = post(conn, "/categories", %{"category" => %{"name" => ""}})
      assert html_response(conn, 200) =~ "Please fix the following errors"
      assert Repo.aggregate(Alkemist.Category, :count) == 0
    end
  end

  describe "export" do
    test "sends csv", %{conn: conn} do
      insert_category!(name: "Exported")
      conn = get(conn, "/categories/export")
      assert response_content_type(conn, :csv) =~ "text/csv"
      assert response(conn, 200) =~ "Exported"
    end

    test "is denied when the provider refuses :export", %{conn: conn} do
      with_provider(DenyExport, fn ->
        assert conn |> get("/categories") |> html_response(200)
        conn = get(conn, "/categories/export")
        assert redirected_to(conn) == "/"
      end)
    end
  end

  describe "forbidden" do
    test "redirects to forbidden_redirect_to with a flash", %{conn: conn} do
      with_provider(DenyAll, fn ->
        conn = get(conn, "/categories")
        assert redirected_to(conn) == "/"
        assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not authorized"
      end)
    end
  end

  describe "nested routes" do
    test "index links use route_params", %{conn: conn} do
      c = insert_category!(name: "Nested")
      p = insert_post!(title: "Inner", category_id: c.id)
      html = conn |> get("/categories/#{c.id}/posts") |> html_response(200)
      assert html =~ "Inner"
      assert html =~ ~s(data-href="/categories/#{c.id}/posts/#{p.id}")
    end
  end

  describe "design features" do
    test "index shows the description, a row actions menu and an icon in the menu", %{conn: conn} do
      c = insert_category!(name: "Menus")
      html = conn |> get("/categories") |> html_response(200)
      assert html =~ "Every category, with its posts."
      assert html =~ ~s(id="ak-row-actions-#{c.id}")
      assert html =~ ~s(aria-label="More actions")
      assert html =~ ~s(class="ak-dropdown__item ak-dropdown__item--danger")
      assert html =~ ~s(data-method="delete")
      assert html =~ ~r/<a href="\/categories" class="ak-nav__link" aria-current="page">\s*<svg/
      assert html =~ ~s(<a href="/categories/#{c.id}" class="ak-td__primary">)
    end

    test "show uses the title option, tabs for tabbed panels and the right column", %{conn: conn} do
      c = insert_category!(name: "Tabbed")
      insert_post!(title: "Inside", category_id: c.id)

      html = conn |> get("/categories/#{c.id}") |> html_response(200)
      assert html =~ ~s(<h1>Tabbed</h1>)
      assert html =~ ~s(<nav class="ak-tabs" aria-label="Sections">)
      assert html =~ ~r/<a href="\/categories\/#{c.id}" class="ak-tab" aria-current="page">\s*Overview/
      assert html =~ ~s(href="/categories/#{c.id}?tab=posts")
      assert html =~ "Category details"
      assert html =~ "Plain notes &lt;b&gt;escaped&lt;/b&gt;"
      refute html =~ ">Inside<"
      assert html =~ ~s(class="ak-columns__aside")
      assert html =~ "1 posts"

      tab = conn |> get("/categories/#{c.id}", %{"tab" => "posts"}) |> html_response(200)
      assert tab =~ "Inside"
      refute tab =~ "Category details"
      refute tab =~ "Plain notes"
    end
  end

  describe "safety" do
    test "html in data is escaped on index and show", %{conn: conn} do
      c = insert_category!(name: "<script>alert(1)</script>")
      html = conn |> get("/categories") |> html_response(200)
      refute html =~ "<script>alert(1)</script>"
      assert html =~ "&lt;script&gt;alert(1)&lt;/script&gt;"
      assert conn |> get("/categories/#{c.id}") |> html_response(200) =~ "&lt;script&gt;"
    end
  end

  describe "compile-time metadata" do
    test "controllers expose their resource and menu item" do
      assert AlkemistTest.CategoryController.__alkemist_resource__() == Alkemist.Category

      assert %{label: "Categories", controller: AlkemistTest.CategoryController} =
               AlkemistTest.CategoryController.__alkemist_menu__()

      assert AlkemistTest.NestedPostController.__alkemist_menu__() == nil
    end
  end
end
