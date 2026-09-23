defmodule Alkemist.Query.ParserTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  doctest Alkemist.Query.Parser

  alias Alkemist.Query.Parser

  test "every suffix yields its operator first" do
    for suffix <- Parser.suffixes() do
      [{"title", op} | _] = Parser.split("title_" <> suffix)
      assert op in Parser.operators(), "#{suffix} -> #{op}"
    end
  end

  test "not_* is preferred over the bare operator" do
    assert [{"title", :not_cont} | _] = Parser.split("title_not_cont")
    assert [{"title", :not_start} | _] = Parser.split("title_not_start")
    assert [{"title", :not_end} | _] = Parser.split("title_not_end")
    assert [{"title", :not_in} | _] = Parser.split("title_not_in")
    assert [{"published_at", :not_null} | _] = Parser.split("published_at_not_null")
  end

  test "a field that ends in an operator word still offers the plain reading" do
    assert {"end_date", :cont} in Parser.split("end_date")
    assert {"status_in", :eq} in Parser.split("status_in_eq")
    assert {"status", :in} in Parser.split("status_in_eq") == false
  end

  test "a lone suffix is not split into an empty field" do
    assert Parser.split("_eq") == [{"_eq", :cont}]
    assert Parser.split("eq") == [{"eq", :cont}]
  end

  property "split never raises and always ends with the whole key as :cont" do
    check all(key <- string(:printable, min_length: 1, max_length: 40)) do
      candidates = Parser.split(key)
      assert List.last(candidates) == {key, :cont}
    end
  end
end
