defmodule Alkemist.MenuRegistryTest do
  use ExUnit.Case, async: true

  alias Alkemist.MenuRegistry

  defmodule TestController do
    def index(_, _), do: :ok
  end

  defmodule Test2Controller do
    def index(_, _), do: :ok
  end

  defmodule NoIndexController do
  end

  setup do
    MenuRegistry.cleanup()
  end

  describe "register_menu_item" do
    test "it registers a menu item when label is set" do
      MenuRegistry.register_menu_item(TestController, "Test", [])
      menu_items = MenuRegistry.menu_items()
      assert length(menu_items) == 1
      menu = Enum.at(menu_items, 0)
      assert menu.label == "Test"
    end

    test "it sorts menu items by index" do
      MenuRegistry.register_menu_item(Test2Controller, "Test 2", index: 2)
      MenuRegistry.register_menu_item(TestController, "Test", index: 1)
      menu_items = MenuRegistry.menu_items()
      assert length(menu_items) == 2
      assert Enum.at(menu_items, 0).label == "Test"
      assert Enum.at(menu_items, 1).label == "Test 2"
    end

    test "it overwrites an already existing menu item when registered a second time" do
      MenuRegistry.register_menu_item(TestController, "Test", [])
      MenuRegistry.register_menu_item(TestController, "Second", [])
      assert Enum.at(MenuRegistry.menu_items(), 0).label == "Second"
    end

    test "it removes an already registered item when label is false" do
      MenuRegistry.register_menu_item(TestController, "Test", [])
      MenuRegistry.register_menu_item(TestController, false, [])
      assert Enum.empty?(MenuRegistry.menu_items())
    end

    test "it moves items into a tree structure when parent is set" do
      MenuRegistry.register_menu_item(TestController, "Test", parent: "Parent", index: 2)
      MenuRegistry.register_menu_item(Test2Controller, "Test 2", parent: "Parent", index: 1)
      menu_items = MenuRegistry.menu_items()
      assert length(menu_items) == 1
      parent = Enum.at(menu_items, 0)

      assert parent.label == "Parent"
      assert parent.type == :branch
      assert length(parent.children) == 2
      assert Enum.at(parent.children, 0).label == "Test 2"
    end
  end
end
