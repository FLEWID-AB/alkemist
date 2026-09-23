defmodule Alkemist.Query.FilterTest do
  use ExUnit.Case, async: true

  alias Alkemist.Query.Filter

  defp one(key, value) do
    {:ok, [filter]} = Filter.parse(Alkemist.Post, key, value)
    filter
  end

  test "casts values to the column type" do
    assert %Filter{op: :eq, value: true} = one("published_eq", "true")
    assert %Filter{op: :lt, value: 10} = one("views_lt", "10")
    assert %Filter{op: :gteq, value: %Decimal{}} = one("price_gteq", "9.5")
    assert %Filter{op: :eq, value: 3} = one("category_id_eq", "3")
  end

  test "drops values that do not cast" do
    assert {:error, :invalid_value} = Filter.parse(Alkemist.Post, "views_lt", "abc")
    assert {:error, :unknown_field} = Filter.parse(Alkemist.Post, "nope_eq", "1")
  end

  test "list operators accept lists and comma-separated strings" do
    assert %Filter{op: :in, value: [1, 2]} = one("category_id_in", "1, 2")
    assert %Filter{op: :in, value: [1, 2]} = one("category_id_in", ["1", "2"])
    assert %Filter{op: :not_in, value: [1]} = one("category_id_not_in", ["1", ""])
    assert {:error, :empty} = Filter.parse(Alkemist.Post, "category_id_in", [""])
  end

  test "a list with eq means membership (multi-select filter form)" do
    assert %Filter{op: :in, value: [1, 2]} = one("category_id_eq", ["1", "2"])
    assert %Filter{op: :not_in, value: [1]} = one("category_id_neq", ["1"])
  end

  test "text operators keep the raw string" do
    assert %Filter{op: :cont, value: "foo"} = one("title_cont", "foo")
    assert %Filter{op: :not_cont, value: "foo"} = one("title_not_ilike", "foo")
    assert %Filter{op: :start, value: "5"} = one("views_start", 5)
    assert {:error, :empty} = Filter.parse(Alkemist.Post, "title_cont", "")
  end

  test "null operators take a boolean-ish value" do
    assert %Filter{op: :null, value: true} = one("category_id_null", "true")
    assert %Filter{op: :null, value: false} = one("category_id_null", "false")
    assert %Filter{op: :not_null, value: true} = one("category_id_not_null", "1")
  end

  describe "date-only values on datetime columns" do
    test "eq expands to a half-open day interval" do
      {:ok, [from, to]} = Filter.parse(Alkemist.Post, "published_at_eq", "2026-01-02")
      assert %Filter{op: :gteq, value: ~N[2026-01-02 00:00:00]} = from
      assert %Filter{op: :lt, value: ~N[2026-01-03 00:00:00]} = to
    end

    test "comparison operators move to the day boundary" do
      assert %Filter{op: :gteq, value: ~N[2026-01-02 00:00:00]} =
               one("published_at_gteq", "2026-01-02")

      assert %Filter{op: :gteq, value: ~N[2026-01-03 00:00:00]} =
               one("published_at_gt", "2026-01-02")

      assert %Filter{op: :lt, value: ~N[2026-01-03 00:00:00]} =
               one("published_at_lteq", "2026-01-02")

      assert %Filter{op: :lt, value: ~N[2026-01-02 00:00:00]} =
               one("published_at_lt", "2026-01-02")
    end

    test "neq becomes not_within" do
      assert %Filter{op: :not_within, value: {~N[2026-01-02 00:00:00], ~N[2026-01-03 00:00:00]}} =
               one("published_at_neq", "2026-01-02")
    end

    test "full datetimes are cast, not expanded" do
      assert %Filter{op: :eq, value: ~N[2026-01-02 10:30:00]} =
               one("published_at_eq", "2026-01-02T10:30:00")
    end
  end
end
