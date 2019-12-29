defmodule Alkemist.Types.ScopeTest do
  use Alkemist.DataCase, async: true
  alias Alkemist.Post
  alias Alkemist.Types.Scope

  @default_opts %{query: Post, repo: Repo, search_provider: Alkemist.Query.Search, params: %{}}

  describe "map" do
    test "it fetches the correct count from the database" do
      post_fixture(%{published: false})
      post_fixture(%{published: true})

      assert %Scope{count: 2} = Scope.map({:all, [], fn q -> q end}, @default_opts)
      assert %Scope{count: 1} = Scope.map({:published, [], fn q -> from(p in q, where: p.published == true) end}, @default_opts)
      assert %Scope{count: 1} = Scope.map({:unpublished, [], fn q -> from(p in q, where: p.published == false) end}, @default_opts)
    end

    test "it sets correct label" do
      assert %Scope{label: "All"} = Scope.map({:all, [], fn q -> q end}, @default_opts)
      assert %Scope{label: "All Posts"} = Scope.map({:all, [label: "All Posts"], fn q -> q end}, @default_opts)
      assert %Scope{label: "All Posts"} = Scope.map(%Scope{key: :all, label: "All Posts", callback: fn q -> q end}, @default_opts)
    end

    test "it sets active scope based on params" do
      assert %Scope{active?: true, default?: true} = Scope.map({:all, [default: true], fn q -> q end}, @default_opts)

      assert %Scope{active?: true, default?: false} = Scope.map({:all, [], fn q -> q end}, Map.put(@default_opts, :params, %{"scope" => "all"}))
    end
  end

  describe "map_all" do
    test "it applies map on a list of scope definitions" do
      defs = [
        {:all, [default: true], fn q -> q end},
        %Scope{key: :published, callback: fn q -> q end},
        {:unpublished, fn q -> q end}
      ]

      assert mapped = Scope.map_all(defs, @default_opts)
      assert Enum.find(mapped, & &1.key == :all && &1.default? == true)
      assert Enum.find(mapped, & &1.key == :published)
      assert Enum.find(mapped, & &1.key == :unpublished)
    end
  end

  describe "scope_query" do
    test "it returns the query altered by callback when a scope is provided" do
      callback = fn q -> from(p in q, where: p.published == true) end
      scope = %Scope{key: :published, active?: true, callback: callback}

      altered_query = callback.(Post)
      assert altered_query == Scope.scope_query(Post, scope)
    end

    test "it returns original query when no scope is given" do
      assert Post == Scope.scope_query(Post, nil)
    end
  end

  describe "scope_by_active" do
    test "it finds the active scope and alters the query" do
      callback = fn q -> from(p in q, where: p.published == true) end

      scopes = [
        %Scope{key: :all, active?: false, callback: fn q -> q end},
        %Scope{key: :published, active?: true, callback: callback}
      ]

      assert callback.(Post) == Scope.scope_by_active(Post, scopes)
    end

    test "it returns original query if no active scope is found" do
      scopes = [
        %Scope{key: :all},
        %Scope{key: :published}
      ]

      assert Post == Scope.scope_by_active(Post, scopes)
    end
  end

  defp post_fixture(params \\ %{}) do
    params =
      params
      |> Map.put_new(:title, "Lorem ipsum")
      |> Map.put_new(:body, "Lorem ipsum body")
      |> Map.put_new(:published, false)

    %Post{}
    |> Post.changeset(params)
    |> Repo.insert!()
  end
end
