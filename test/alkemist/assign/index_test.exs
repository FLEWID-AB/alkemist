defmodule Alkemist.Assign.IndexTest do
  use Alkemist.DataCase, async: true

  alias Alkemist.Assign.Index
  alias Alkemist.Post
  alias Alkemist.Fixtures
  doctest Index

  import Ecto.Query, only: [from: 2]

  describe "assigns" do
    test "it creates default index assigns" do
      for _ <- 1..20 do
        Fixtures.post_fixture()
      end

      assigns = Index.assigns(%{}, Post)

      assert length(assigns[:entries]) == 10
      assert length(assigns[:columns]) == 5
      assert assigns[:resource] == Post
      assert is_map(assigns[:pagination])
      assert assigns[:scopes] == []
      assert assigns[:filters] == []
      refute assigns[:search]
      assert assigns[:struct] == :post
    end

    test "it customizes columns" do
      opts = [
        columns: [:id, :title, :body]
      ]
      assigns = Index.assigns(%{}, Post, opts)
      assert length(assigns[:columns]) == 3

      for col <- opts[:columns] do
        assert Enum.find(assigns[:columns], & &1.field == col)
      end
    end

    test "it works with scopes" do
      Fixtures.post_fixture()
      Fixtures.post_fixture(%{published: false})

      opts = [
        scopes: [
          {:published, fn q -> from p in q, where: p.published == true end},
          {:unpublished, fn q -> from p in q, where: p.published == false end}
        ]
      ]

      assigns = Index.assigns(%{}, Post, opts)
      assert length(assigns[:scopes]) == 2
      assert length(assigns[:entries]) == 2

      published_assigns = Index.assigns(%{"scope" => "published"}, Post, opts)
      assert length(published_assigns[:entries]) == 1

      unpublished_assigns = Index.assigns(%{"scope" => "unpublished"}, Post, opts)
      assert length(unpublished_assigns[:entries]) == 1
    end

    test "it adds selectable column as first one when we provide batch actions" do
      opts = [
        batch_actions: [:delete_batch]
      ]

      assigns = Index.assigns(%{}, Post, opts)
      assert length(assigns[:batch_actions]) == 1
      assert Enum.at(assigns[:columns], 0).field == :selectable_column
    end

    test "if we already have selectable column, it will skip this" do
      opts = [
        columns: [:selectable_column, :id, :title],
        batch_actions: [:delete_batch]
      ]
      assigns = Index.assigns(%{}, Post, opts)
      assert length(assigns[:columns]) == 3
    end
  end

  describe "default_opts" do
    test "it populates the opts passed to this method with defaults" do
      assert defaults = Index.default_opts([], Post)

      assert defaults[:query] == Post
      Enum.each([:id, :title, :body, :category_id], fn col ->
        assert Enum.member?(defaults[:columns], col)
      end)
      assert defaults[:scopes] == []
      assert defaults[:filters] == []
      refute defaults[:show_aside]
      assert defaults[:search_provider] == Alkemist.Query.Search
      assert defaults[:pagination_provider] == Alkemist.Query.Paginate
      assert defaults[:mod] == Post
      assert defaults[:batch_actions] == []
      assert defaults[:sidebars] == []
      assert defaults[:sort_by] == "id+desc"
    end
  end

end
