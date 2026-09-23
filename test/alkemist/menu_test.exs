defmodule Alkemist.MenuTest do
  use ExUnit.Case, async: true

  alias Alkemist.Menu

  test "items are derived from the router, not from a process" do
    items = Menu.items(AlkemistTest.Router)
    labels = Enum.map(items, & &1.label)

    assert "Categories" in labels
    assert "Posts" in labels
    assert "Uuid Items" in labels
    # menu(false) hides the nested controller; plain controllers are not resources
    refute Enum.any?(items, &(&1[:controller] == AlkemistTest.NestedPostController))
    refute Enum.any?(items, &(&1[:controller] == AlkemistTest.PlainController))
    assert labels == Enum.sort(labels)
  end

  test "items carry the controller so links can be built without helpers" do
    %{controller: controller, resource: resource} =
      Enum.find(Menu.items(AlkemistTest.Router), &(&1.label == "Categories"))

    assert controller == AlkemistTest.CategoryController
    assert resource == Alkemist.Category
  end

  test "children are grouped under a parent branch and sorted" do
    tree =
      [
        Menu.item(A, "A", "Zeta", index: 1),
        Menu.item(B, "B", "Child B", parent: "Group", parent_index: 0, index: 2),
        Menu.item(C, "C", "Child A", parent: "Group", index: 1),
        Menu.item(D, "D", "Alpha", index: 0)
      ]
      |> then(fn items -> :erlang.apply(Menu, :__test_build_tree__, [items]) end)

    assert [
             %{label: "Alpha"},
             %{
               label: "Group",
               type: :branch,
               children: [%{label: "Child A"}, %{label: "Child B"}]
             },
             %{label: "Zeta"}
           ] =
             tree
  end

  test "menu false and custom labels" do
    assert Menu.item(X, Alkemist.Post, false, []) == nil

    assert %{label: "Reports", resource: "Reports", to: "/reports"} =
             Menu.item(X, nil, "Reports", to: "/reports")

    assert %{label: "Posts", resource: Alkemist.Post} = Menu.default_item(X, Alkemist.Post)
  end

  test "caching per router can be reset" do
    assert Menu.items(AlkemistTest.Router, cache: true) == Menu.items(AlkemistTest.Router)
    assert :ok = Menu.reset(AlkemistTest.Router)
  end
end
