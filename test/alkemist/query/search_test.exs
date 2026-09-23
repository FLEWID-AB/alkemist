defmodule Alkemist.Query.SearchTest do
  use Alkemist.DataCase, async: true

  alias Alkemist.{Post, Category, Tag}
  alias Alkemist.Query.Search

  setup do
    news = insert_category!(name: "News")
    sport = insert_category!(name: "Sport")
    elixir = insert_tag!(name: "elixir")
    erlang = insert_tag!(name: "erlang")

    p1 =
      insert_post!(
        title: "Hello world",
        views: 10,
        published: true,
        published_at: ~N[2026-01-02 08:00:00],
        category_id: news.id
      )

    p2 =
      insert_post!(
        title: "Hello again",
        views: 20,
        published: false,
        published_at: ~N[2026-01-02 23:30:00],
        category_id: news.id
      )

    p3 =
      insert_post!(
        title: "Goodbye",
        views: 30,
        published: true,
        published_at: ~N[2026-01-03 00:00:00],
        category_id: sport.id
      )

    Repo.insert_all("posts_tags", [
      %{post_id: p1.id, tag_id: elixir.id},
      %{post_id: p1.id, tag_id: erlang.id},
      %{post_id: p2.id, tag_id: elixir.id}
    ])

    %{news: news, sport: sport, p1: p1, p2: p2, p3: p3}
  end

  defp titles(query), do: query |> Repo.all() |> Enum.map(& &1.title) |> Enum.sort()
  defp run(params, schema \\ Post), do: Search.run(schema, params, schema: schema, repo: Repo)

  test "contains, starts with and ends with are case-insensitive and literal" do
    assert titles(run(%{"q" => %{"title_cont" => "hello"}})) == ["Hello again", "Hello world"]
    assert titles(run(%{"q" => %{"title" => "HELLO"}})) == ["Hello again", "Hello world"]
    assert titles(run(%{"q" => %{"title_start" => "good"}})) == ["Goodbye"]
    assert titles(run(%{"q" => %{"title_end" => "world"}})) == ["Hello world"]
    assert titles(run(%{"q" => %{"title_not_ilike" => "hello"}})) == ["Goodbye"]
    assert titles(run(%{"q" => %{"title_cont" => "%"}})) == []
  end

  test "comparisons and membership" do
    assert titles(run(%{"q" => %{"views_gt" => "10"}})) == ["Goodbye", "Hello again"]
    assert titles(run(%{"q" => %{"views_in" => "10,30"}})) == ["Goodbye", "Hello world"]
    assert titles(run(%{"q" => %{"published_eq" => "true"}})) == ["Goodbye", "Hello world"]

    assert titles(run(%{"q" => %{"views_cont" => "0"}})) == [
             "Goodbye",
             "Hello again",
             "Hello world"
           ]
  end

  test "date-only filters cover the whole day" do
    assert titles(run(%{"q" => %{"published_at_eq" => "2026-01-02"}})) == [
             "Hello again",
             "Hello world"
           ]

    assert titles(run(%{"q" => %{"published_at_neq" => "2026-01-02"}})) == ["Goodbye"]
    assert titles(run(%{"q" => %{"published_at_gt" => "2026-01-02"}})) == ["Goodbye"]

    assert titles(
             run(%{
               "q" => %{"published_at_gteq" => "2026-01-02", "published_at_lteq" => "2026-01-02"}
             })
           ) ==
             ["Hello again", "Hello world"]
  end

  test "unknown fields and bad values are ignored, not errors" do
    assert titles(run(%{"q" => %{"bogus_eq" => "1", "views_lt" => "abc", "title_cont" => "hello"}})) ==
             ["Hello again", "Hello world"]
  end

  test "belongs_to filters join once and keep counts right", %{news: news} do
    query =
      run(%{"q" => %{"category_assoc_name_eq" => "News", "category_assoc_id_eq" => "#{news.id}"}})

    assert titles(query) == ["Hello again", "Hello world"]
    assert Alkemist.Query.count(query, Repo) == 2
    assert length(query.joins) == 1
  end

  test "has_many and many_to_many filters do not inflate the root" do
    query = run(%{"q" => %{"posts_assoc_title_cont" => "hello"}}, Category)
    assert query |> Repo.all() |> Enum.map(& &1.name) == ["News"]
    assert Alkemist.Query.count(query, Repo) == 1
    assert query.joins == []

    query = run(%{"q" => %{"tags_assoc_name_eq" => "elixir"}})
    assert titles(query) == ["Hello again", "Hello world"]
    assert Alkemist.Query.count(query, Repo) == 2
  end

  test "sorting, including by an association column" do
    assert run(%{"s" => "views+desc"}) |> Repo.all() |> Enum.map(& &1.views) == [30, 20, 10]
    assert run(%{"s" => "views desc"}) |> Repo.all() |> Enum.map(& &1.views) == [30, 20, 10]

    assert run(%{"s" => "category_assoc_name+desc", "q" => %{"published_eq" => "true"}})
           |> Repo.all()
           |> Enum.map(& &1.title) ==
             ["Goodbye", "Hello world"]

    assert run(%{"s" => "bogus+desc"}) |> Repo.all() |> length() == 3
  end

  test "works on a query the host has already aliased or filtered" do
    base = from(p in Post, as: :post, where: p.published == true)
    query = Search.run(base, %{"q" => %{"title_cont" => "hello"}, "s" => "title+asc"}, repo: Repo)
    assert titles(query) == ["Hello world"]
  end

  test "filter/3 alone applies no ordering" do
    query =
      Search.filter(Post, %{"s" => "views+desc", "q" => %{"views_gt" => "10"}}, schema: Post)

    assert query.order_bys == []
    assert Repo.aggregate(query, :count) == 2
  end

  test "tag filter subquery works from the Tag side too" do
    query = run(%{"q" => %{"posts_assoc_views_gteq" => "20"}}, Tag)
    assert query |> Repo.all() |> Enum.map(& &1.name) == ["elixir"]
  end
end
