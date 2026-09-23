defmodule Alkemist.SchemaTest do
  use ExUnit.Case, async: true
  alias Alkemist.Schema

  test "primary_key!/1" do
    assert Schema.primary_key!(Alkemist.Post) == {:id, :id}
    assert Schema.primary_key!(Alkemist.UuidItem) == {:id, :binary_id}
  end

  test "default_sort/1" do
    assert Schema.default_sort(Alkemist.Post) == "id+desc"
  end

  test "from_queryable/2" do
    import Ecto.Query
    assert Schema.from_queryable(Alkemist.Post) == Alkemist.Post
    assert Schema.from_queryable(from(p in Alkemist.Post, where: p.published)) == Alkemist.Post

    assert Schema.from_queryable(from(p in "posts", select: p.id), schema: Alkemist.Post) ==
             Alkemist.Post

    assert_raise ArgumentError, fn -> Schema.from_queryable(from(p in "posts", select: p.id)) end
    assert_raise ArgumentError, fn -> Schema.from_queryable(Enum) end
  end
end
