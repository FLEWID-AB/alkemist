defmodule Alkemist.NamingTest do
  use ExUnit.Case, async: true
  doctest Alkemist.Naming

  alias Alkemist.Naming

  test "resource_key ignores the table name and uses the module" do
    assert Naming.resource_key(Alkemist.Category) == :category
    assert Naming.plural_label(Alkemist.Category) == "Categories"
    assert Naming.singular_label(Alkemist.Category) == "Category"
  end

  test "humanize keeps inner capitals" do
    assert Naming.humanize("myModel_name") == "MyModel Name"
  end

  test "pluralize regular and irregular words" do
    assert Naming.pluralize("church") == "churches"
    assert Naming.pluralize("day") == "days"
    assert Naming.pluralize("child") == "children"
  end
end
