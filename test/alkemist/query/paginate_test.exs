defmodule Alkemist.Query.PaginateTest do
  use Alkemist.DataCase, async: false

  alias Alkemist.Post
  alias Alkemist.Query.{Page, Paginate}

  setup do
    for i <- 1..25, do: insert_post!(title: "Post #{i}", views: i)
    :ok
  end

  defp run(params, opts \\ []) do
    Paginate.run(
      order_by(Post, asc: :views),
      params,
      Keyword.merge([repo: Repo, schema: Post], opts)
    )
  end

  test "defaults to page 1 with 10 per page" do
    {query, page} = run(%{})

    assert %Page{
             current_page: 1,
             per_page: 10,
             total_count: 25,
             total_pages: 3,
             next_page: 2,
             prev_page: nil
           } = page

    assert query |> Repo.all() |> Enum.map(& &1.views) == Enum.to_list(1..10)
  end

  test "honours page and per_page in string or integer form" do
    {query, page} = run(%{"page" => "2", "per_page" => "5"})
    assert %Page{current_page: 2, per_page: 5, total_pages: 5, prev_page: 1, next_page: 3} = page
    assert query |> Repo.all() |> Enum.map(& &1.views) == [6, 7, 8, 9, 10]

    {_query, page} = run(%{page: 3, per_page: 10})
    assert %Page{current_page: 3, next_page: nil, prev_page: 2} = page
  end

  test "clamps per_page to max_per_page and page to the last page" do
    {_query, page} = run(%{"per_page" => "100000"})
    assert page.per_page == 100

    {query, page} = run(%{"page" => "999", "per_page" => "10"})
    assert page.current_page == 3
    assert query |> Repo.all() |> length() == 5
  end

  test "invalid values fall back to defaults" do
    for params <- [
          %{"page" => "-1", "per_page" => "0"},
          %{"page" => "abc"},
          %{"page" => "", "per_page" => ""},
          nil
        ] do
      {_query, page} = run(params)
      assert %Page{current_page: 1, per_page: 10} = page
    end
  end

  test "an empty result is page 1 of 0" do
    Repo.delete_all(Post)
    {query, page} = run(%{"page" => "4"})

    assert %Page{current_page: 1, total_pages: 0, total_count: 0, next_page: nil, prev_page: nil} =
             page

    assert Repo.all(query) == []
  end

  test "works for a schema without an integer id" do
    for n <- 1..3, do: Repo.insert!(%Alkemist.UuidItem{name: "item #{n}"})

    {query, page} =
      Paginate.run(Alkemist.UuidItem, %{"per_page" => "2"}, repo: Repo, schema: Alkemist.UuidItem)

    assert page.total_count == 3
    assert query |> Repo.all() |> length() == 2
  end

  test "runs exactly one count query and one page query" do
    handler = "paginate-test-#{System.unique_integer([:positive])}"
    test_pid = self()

    :telemetry.attach(
      handler,
      [:alkemist, :repo, :query],
      fn _event, _measurements, meta, _ -> send(test_pid, {:query, meta.query}) end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler) end)

    {query, _page} = run(%{"page" => "2"})
    Repo.all(query)

    queries = collect_queries([])
    assert length(queries) == 2, "expected 2 queries, got:\n" <> Enum.join(queries, "\n")
    assert Enum.count(queries, &String.contains?(&1, "count(*)")) == 1
  end

  test "requires a repo" do
    assert_raise KeyError, fn -> Paginate.run(Post, %{}, schema: Post) end
  end

  defp collect_queries(acc) do
    receive do
      {:query, sql} -> collect_queries([sql | acc])
    after
      50 -> Enum.reverse(acc)
    end
  end
end
