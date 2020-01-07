defmodule Alkemist.Assign.ShowTest do
  use Alkemist.DataCase, async: true
  alias Alkemist.Assign.Show
  import Alkemist.Factory
  alias TestAlkemist.Post
  doctest Show

  describe "default_opts" do
    test "it adds default generated options" do
      opts = Show.default_opts([], TestAlkemist.Alkemist, Post)
      assert opts[:resource] == Post
      assert length(opts[:rows]) == 5
    end

    test "it customizes rows when passed" do
      opts = Show.default_opts([rows: [:id, :title]], TestAlkemist.Alkemist, Post)
      assert length(opts[:rows]) == 2
    end
  end

  describe "assigns" do
    test "it creates default assigns" do
      post = insert!(:post)

      assert assigns = Show.assigns(TestAlkemist.Alkemist, post, [])
      assert assigns[:resource] == post
      assert assigns[:struct] == :post
      assert assigns[:mod] == Post
      assert assigns[:panels] == []
      assert length(assigns[:rows]) == 5
    end

    test "it preloads resource" do
      category = insert!(:category)
      post = insert!(:post, category: category)

      assert assigns = Show.assigns(TestAlkemist.Alkemist, post, [preload: [:category]])
      assert assigns[:resource].category.id == category.id
    end
  end
end
