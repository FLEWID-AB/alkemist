defmodule Alkemist.DataCaseSmokeTest do
  use Alkemist.DataCase, async: true

  test "migrations ran and the sandbox isolates inserts" do
    category = insert_category!(name: "News")
    post = insert_post!(title: "Hello", category_id: category.id)
    tag = insert_tag!(name: "elixir")

    Repo.insert_all("posts_tags", [%{post_id: post.id, tag_id: tag.id}])

    loaded = Repo.get!(Alkemist.Post, post.id) |> Repo.preload([:category, :tags])
    assert loaded.category.name == "News"
    assert [%Alkemist.Tag{name: "elixir"}] = loaded.tags
    assert Repo.aggregate(Alkemist.Post, :count) == 1
  end

  test "binary_id fixture works" do
    item = %Alkemist.UuidItem{} |> Alkemist.UuidItem.changeset(%{name: "x"}) |> Repo.insert!()
    assert is_binary(item.id) and String.length(item.id) == 36
  end
end
