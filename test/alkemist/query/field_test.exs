defmodule Alkemist.Query.FieldTest do
  use ExUnit.Case, async: true
  doctest Alkemist.Query.Field

  alias Alkemist.Query.Field

  test "resolves belongs_to and many_to_many fields" do
    assert {:ok, %Field{binding: :category, name: :name}} =
             Field.resolve(Alkemist.Post, "category_assoc_name")

    assert {:ok, %Field{binding: :tags, name: :name, assoc: %{cardinality: :many}}} =
             Field.resolve(Alkemist.Post, "tags_assoc_name")

    assert {:ok, %Field{binding: :posts, name: :title}} =
             Field.resolve(Alkemist.Category, "posts_assoc_title")
  end

  test "unknown associations and fields are errors" do
    assert {:error, :unknown_field} = Field.resolve(Alkemist.Post, "author_assoc_name")
    assert {:error, :unknown_field} = Field.resolve(Alkemist.Post, "category_assoc_nope")
  end

  test "resolve_key picks the first reading that exists on the schema" do
    assert {:ok, %Field{name: :title}, :not_cont} =
             Field.resolve_key(Alkemist.Post, "title_not_ilike")

    assert {:ok, %Field{name: :published_at}, :gteq} =
             Field.resolve_key(Alkemist.Post, "published_at_gteq")

    assert {:ok, %Field{name: :title}, :cont} = Field.resolve_key(Alkemist.Post, "title")
    assert {:error, :unknown_field} = Field.resolve_key(Alkemist.Post, "title_not")
  end

  test "resolving arbitrary keys never creates atoms" do
    # Long random keys, pre-filtered so none is already an atom (short words like "id" are).
    keys =
      for _ <- 1..2000, key = random_key(), not existing_atom?(key), uniq: true, do: key

    for key <- keys do
      Field.resolve_key(Alkemist.Post, key <> "_eq")
      Field.resolve(Alkemist.Post, key <> "_assoc_" <> key)
      Field.resolve(Alkemist.Post, key)

      for candidate <- [key, key <> "_eq", key <> "_assoc_" <> key] do
        assert_raise ArgumentError, fn -> String.to_existing_atom(candidate) end
      end
    end
  end

  defp random_key do
    for _ <- 1..Enum.random(10..16), into: "", do: <<Enum.random(?a..?z)>>
  end

  defp existing_atom?(string) do
    _ = String.to_existing_atom(string)
    true
  rescue
    ArgumentError -> false
  end
end
