defmodule Alkemist.Query.SortTest do
  use ExUnit.Case, async: true
  doctest Alkemist.Query.Sort

  alias Alkemist.Query.Sort

  test "sorting by a belongs_to field is allowed" do
    assert {:ok, %{binding: :category, name: :name}, :asc} =
             Sort.parse(Alkemist.Post, "category_assoc_name+asc")
  end

  test "nulls variants" do
    assert {:ok, _, :desc_nulls_last} = Sort.parse(Alkemist.Post, "views+desc_nulls_last")
    assert {:ok, _, :asc} = Sort.parse(Alkemist.Post, "views+sideways")
  end

  test "non-binary input is invalid" do
    assert {:error, :invalid} = Sort.parse(Alkemist.Post, nil)
    assert {:error, :invalid} = Sort.parse(Alkemist.Post, %{})
  end
end
