defmodule Alkemist.QueryTest do
  use Alkemist.DataCase, async: true

  alias Alkemist.{Category, Post, Query}

  test "count ignores ordering, selection, limit and preloads" do
    c = insert_category!()
    for i <- 1..4, do: insert_post!(title: "p#{i}", category_id: c.id)

    query = from(p in Post, order_by: p.title, limit: 2, select: p.title, preload: :category)
    assert Query.count(query, Repo) == 4
  end

  test "count is correct for distinct and grouped queries" do
    c = insert_category!()
    insert_post!(title: "a", category_id: c.id)
    insert_post!(title: "b", category_id: c.id)

    assert Query.count(from(p in Post, distinct: p.category_id), Repo) == 1
    assert Query.count(from(p in Post, group_by: p.category_id, select: p.category_id), Repo) == 1
    assert Query.count(Category, Repo) == 1
  end
end
