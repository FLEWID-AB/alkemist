defmodule Alkemist.IndexComponentsTest do
  use ExUnit.Case, async: true
  doctest Alkemist.Components.Pagination
  import Phoenix.LiveViewTest, only: [render_component: 2]

  alias Alkemist.Components.{Filters, Pagination, Table, Value}
  alias Alkemist.Paths

  defp conn,
    do: Phoenix.ConnTest.build_conn(:get, "/posts") |> Plug.Conn.put_private(:phoenix_router, AlkemistTest.Router)

  defp paths, do: Paths.new(conn(), AlkemistTest.PostController)

  defp columns do
    [
      {:id, & &1.id, %{label: "Id", type: :integer, sortable: true}},
      {:title, & &1.title, %{label: "Title", type: :string, sortable: true}},
      {:published, & &1.published, %{label: "Published", type: :boolean}},
      {:category, &(&1.category && &1.category.name),
       %{label: "Category", type: :select, assoc: :category, resource: Alkemist.Category, action: :show}}
    ]
  end

  describe "value" do
    test "escapes strings and passes safe html through" do
      assert render_component(&Value.value/1, value: "<b>x</b>") == "&lt;b&gt;x&lt;/b&gt;"
      assert render_component(&Value.value/1, value: {:safe, "<b>x</b>"}) == "<b>x</b>"
    end

    test "formats typed values" do
      assert render_component(&Value.value/1, value: true) =~ ~s(aria-label="true")

      assert render_component(&Value.value/1, value: ~D[2026-01-02]) =~
               ~s(<time datetime="2026-01-02">2026-01-02</time>)

      assert render_component(&Value.value/1, value: ~N[2026-01-02 09:05:00]) =~ "2026-01-02 09:05"
      assert render_component(&Value.value/1, value: nil) =~ "ak-faint"
      assert render_component(&Value.value/1, value: %{a: 1}) =~ ~s(<code class="ak-code">{&quot;a&quot;:1}</code>)
      assert render_component(&Value.value/1, value: Decimal.new("9.50")) =~ "9.50"
    end

    test "per-column format wins" do
      assert render_component(&Value.value/1, value: 5, column: %{format: fn v, _row -> "#{v} pcs" end}) ==
               ~s(<span class="tabular-nums">5 pcs</span>) or
               render_component(&Value.value/1, value: 5, column: %{format: fn v, _row -> "#{v} pcs" end}) == "5 pcs"
    end
  end

  describe "index_table" do
    test "renders sortable headers, escaped cells, row links and assoc links" do
      cat = %Alkemist.Category{id: 3, name: "News"}
      rows = [%Alkemist.Post{id: 1, title: "<i>x</i>", published: true, category: cat}]

      html =
        render_component(&Table.index_table/1,
          columns: columns(),
          entries: rows,
          paths: paths(),
          link_params: %{"q" => %{"title_ilike" => "x"}},
          sort: {"title", "asc"},
          struct: :post,
          conn: conn()
        )

      assert html =~ ~s(aria-sort="ascending")
      assert html =~ ~s(href="/posts?q[title_ilike]=x&amp;s=title%2Bdesc")
      assert html =~ ~s(href="/posts?q[title_ilike]=x&amp;s=id%2Basc")
      assert html =~ ~s(id="post-1")
      assert html =~ ~s(data-href="/posts/1")
      assert html =~ "&lt;i&gt;x&lt;/i&gt;"
      refute html =~ "<i>x</i>"
      assert html =~ ~s(<a href="/categories/3">)
    end

    test "batch mode adds checkboxes bound to the batch form" do
      html =
        render_component(&Table.index_table/1,
          columns: columns(),
          entries: [%Alkemist.Post{id: 7}],
          paths: paths(),
          struct: :post,
          conn: conn(),
          batch: true
        )

      assert html =~ ~s(data-batch-select-all)
      assert html =~ ~s(name="batch_ids[]" value="7" form="batch-action-form")
      assert html =~ ~s(phx-hook="AlkemistBatchSelect")
    end
  end

  describe "filters" do
    test "keeps the request dialect: a search box plus dropdown filters" do
      filters = [
        {:title, %{primary: true, placeholder: "Search titles"}},
        {:published, %{type: :boolean}},
        {:published_at, %{type: :date}},
        {:category_id, %{type: :select, collection: [{"News", 1}]}},
        {:views, %{type: :integer}}
      ]

      form = Phoenix.Component.to_form(%{"title_ilike" => "hello", "category_id_eq" => "1"}, as: :q)

      html =
        render_component(&Filters.filter_form/1,
          filters: filters,
          filter_form: form,
          paths: paths(),
          link_params: %{"s" => "id+desc", "scope" => "all"},
          search: true
        )

      assert html =~ ~r/<form [^>]*action="\/posts"/
      assert html =~ ~s(id="index-search-form")
      assert html =~ ~s(phx-hook="AlkemistSearchShortcut")
      assert html =~ ~s(name="q[title_ilike]" value="hello" placeholder="Search titles")
      assert html =~ "data-search-input"
      assert html =~ ~s(name="q[published_eq]")
      assert html =~ ~s(name="q[published_at_gteq]")
      assert html =~ ~s(name="q[published_at_lteq]")
      assert html =~ ~s(name="q[category_id_eq]")
      assert html =~ ~s(name="q[views_eq]")
      assert html =~ ~s(<input type="hidden" name="s" value="id+desc">)
      assert html =~ ~s(<input type="hidden" name="scope" value="all">)
      # each non-search filter is a dropdown button showing its current value
      assert html =~
               ~r/<summary class="ak-filter-button ak-filter-button--active"[^>]*>\s*<span class="ak-filter-button__label">Category Id<\/span> News/

      assert html =~ ~r/<span class="ak-filter-button__label">Published<\/span> Any/
      assert html =~ "Last 30 days"
      assert html =~ ~r/Published At<\/span> Any/
      assert html =~ "Clear"
    end

    test "the first text filter becomes the search box when none is primary" do
      assert {{:name, %{}}, [{:active, %{type: :boolean}}]} =
               Filters.split_search([{:active, %{type: :boolean}}, {:name, %{}}])
    end

    test "a one-sided date range reads from / until" do
      form = Phoenix.Component.to_form(%{"published_at_gteq" => "2026-01-01"}, as: :q)
      html = render_component(&Filters.filter_field/1, form: form, filter: {:published_at, %{type: :date}})
      assert html =~ "from 2026-01-01"

      form = Phoenix.Component.to_form(%{"published_at_lteq" => "2026-02-01"}, as: :q)

      assert render_component(&Filters.filter_field/1, form: form, filter: {:published_at, %{type: :date}}) =~
               "until 2026-02-01"
    end

    test "param_name" do
      assert Filters.param_name(:title, :string) == "title_ilike"
      assert Filters.param_name(:d, :date) == "d_gteq"
      assert Filters.param_name(:n, :integer) == "n_eq"
    end
  end

  describe "pagination" do
    test "renders the range, pages with gaps and the rows-per-page selector" do
      page = %Alkemist.Query.Page{
        current_page: 5,
        total_pages: 10,
        per_page: 10,
        total_count: 100,
        next_page: 6,
        prev_page: 4
      }

      html =
        render_component(&Pagination.pagination/1,
          pagination: page,
          entries_count: 10,
          paths: paths(),
          link_params: %{"s" => "id+desc"}
        )

      assert html =~ "41–50 of 100"
      for p <- [1, 4, 5, 6, 10], do: assert(html =~ ">#{p}</span>")
      refute html =~ ">3</span>"
      assert html =~ "…"
      assert html =~ ~s(href="/posts?page=6&amp;s=id%2Bdesc")
      assert html =~ ~s(aria-current="page")
      assert html =~ "Rows per page"
      assert html =~ ~s(<option value="25">25</option>)
    end

    test "first page disables previous and large counts are grouped" do
      page = %Alkemist.Query.Page{current_page: 1, total_pages: 2785, per_page: 10, total_count: 27_850, next_page: 2}
      html = render_component(&Pagination.pagination/1, pagination: page, entries_count: 10, paths: paths())
      assert html =~ ~s(aria-disabled="true")
      assert html =~ "1–10 of 27 850"
      assert html =~ ">2 785</span>"
    end

    test "window/2" do
      assert Pagination.window(1, 1) == [1]
      assert Pagination.window(2785, 2785) == [1, :gap, 2783, 2784, 2785]
    end
  end
end
