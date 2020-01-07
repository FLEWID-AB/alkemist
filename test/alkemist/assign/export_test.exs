defmodule Alkemist.Assign.ExportTest do
  use Alkemist.DataCase, async: true
  import Alkemist.{Factory}
  alias TestAlkemist.Post
  alias Alkemist.Assign.Export

  describe "assigns" do
    test "it creates default assigns" do
      assert assigns = Export.assigns(TestAlkemist.Alkemist, Post, [], %{})
      assert assigns[:columns]
      assert length(assigns[:columns]) == 5
      assert assigns[:entries]
      assert Enum.empty?(assigns[:entries])
    end

    test "it fetches data unpaginated" do
      insert_list!(20, :post)
      assigns = Export.assigns(TestAlkemist.Alkemist, Post, [], %{})
      assert length(assigns[:entries]) == 20
    end

    test "it applies sort and search params" do
      insert!(:post, title: "Z Post")
      insert!(:post, title: "M Post")
      insert!(:post, title: "Custom Title")

      assigns = Export.assigns(TestAlkemist.Alkemist, Post, [], %{"s" => "title+asc", "q" => %{"title_ilike" => "post"}})
      assert length(assigns[:entries]) == 2
      assert Enum.at(assigns[:entries], 0).title == "M Post"
    end
  end
end
