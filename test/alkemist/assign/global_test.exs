defmodule Alkemist.Assign.GlobalTest do
  use ExUnit.Case, async: true

  alias Alkemist.Assign.Global
  alias Alkemist.Post
  alias Alkemist.Types.Action

  describe "opts" do
    test "it returns a keyword list with default options" do
      assert opts = Global.opts([], Alkemist.TestImplementation, Post)

      assert opts[:alkemist_app] == :alkemist
      assert opts[:implementation] == Alkemist.TestImplementation
      assert opts[:repo] == Alkemist.Repo
      assert opts[:collection_actions] == Action.default_collection_actions()
      assert opts[:member_actions] == Action.default_member_actions()
      assert opts[:singular_name] == "Post"
      assert opts[:plural_name] == "Posts"
      assert opts[:route_params] == []
    end
  end

  describe "assign" do
    test "it creates a list with default assigns" do
      opts = Global.opts([], Alkemist.TestImplementation, Post)

      assert assigns = Global.assigns(opts)

      assert length(assigns[:member_actions]) == 3
      assert [%Action{action: :new}] = assigns[:collection_actions]

      assert assigns[:alkemist_app]
      assert assigns[:singular_name]
      assert assigns[:plural_name]
      assert assigns[:route_params]
    end
  end

  describe "preload" do
    test "it preloads resources" do
      assert query = Global.preload(Post, [:category])

      assert %Ecto.Query{
        preloads: [[:category]]
      } = query
    end
  end
end
