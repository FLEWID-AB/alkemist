defmodule Alkemist.Assign.ExportTest do
  use Alkemist.DataCase, async: true
  alias Alkemist.{Fixtures, Post}
  alias Alkemist.Assign.Export

  describe "assigns" do
    test "it creates default assigns" do
      assert assigns = Export.assigns(Alkemist.TestImplementation, Post, [], %{})
      assert assigns[:columns]
      assert length(assigns[:columns]) == 5
      assert assigns[:entries]
      assert Enum.empty?(assigns[:entries])
    end

    test "it fetches data unpaginated" do
      for _ <- 1..20 do
        Fixtures.post_fixture()
      end
      assigns = Export.assigns(Alkemist.TestImplementation, Post, [], %{})
      assert length(assigns[:entries]) == 20
    end

    test "it applies sort and search params" do
      Fixtures.post_fixture(%{title: "Z Post"})
      Fixtures.post_fixture(%{title: "M Post"})
      Fixtures.post_fixture(%{title: "Custom Title"})

      assigns = Export.assigns(Alkemist.TestImplementation, Post, [], %{"s" => "title+asc", "q" => %{"title_ilike" => "post"}})
      assert length(assigns[:entries]) == 2
      assert Enum.at(assigns[:entries], 0).title == "M Post"
    end
  end
end
