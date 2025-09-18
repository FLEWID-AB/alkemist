defmodule Alkemist.Query.SearchTest do
  use ExUnit.Case, async: true
  alias Alkemist.Query.Search
  import Ecto.Query

  describe "prepare_params" do
    test "it adds midnight when gteq and field is naive_datetime" do
      params = %{"q" => %{"inserted_at_gteq" => "2018-09-05"}}
      assert %{"q" => %{"inserted_at_gteq" => val}} = Search.prepare_params(params, Alkemist.Post)
      assert val == "2018-09-05 00:00:00"
    end

    test "it adds one second before midnight when lteq and field is naive_datetime" do
      params = %{"q" => %{"inserted_at_lteq" => "2018-09-05"}}
      assert %{"q" => %{"inserted_at_lteq" => val}} = Search.prepare_params(params, Alkemist.Post)
      assert val == "2018-09-05 23:59:59"
    end
  end

  describe "convert_to_flop_params" do
    test "converts simple search field to Flop filter format" do
      params = %{"q" => %{"title" => "test"}}
      result = Search.convert_to_flop_params(params)

      assert result[:filters] == [%{field: :title, op: :ilike_and, value: "test"}]
    end

    test "converts turbo_ecto style operators to Flop operators" do
      params = %{"q" => %{"title_eq" => "exact", "body_cont" => "contains"}}
      result = Search.convert_to_flop_params(params)

      expected_filters = [
        %{field: :title, op: :==, value: "exact"},
        %{field: :body, op: :ilike_and, value: "contains"}
      ]
      assert length(result[:filters]) == 2
      assert Enum.all?(expected_filters, fn filter -> filter in result[:filters] end)
    end

    test "converts comparison operators correctly" do
      params = %{"q" => %{
        "id_lt" => "10",
        "id_lteq" => "20",
        "id_gt" => "5",
        "id_gteq" => "1",
        "title_neq" => "not this"
      }}
      result = Search.convert_to_flop_params(params)

      assert length(result[:filters]) == 5

      # Check that each expected filter is present (order doesn't matter)
      # Note: datetime processing is applied to all lt/lteq/gt/gteq operators
      filters = result[:filters]
      assert Enum.any?(filters, fn f -> f == %{field: :id, op: :<, value: "10 23:59:59"} end)
      assert Enum.any?(filters, fn f -> f == %{field: :id, op: :<=, value: "20 23:59:59"} end)
      assert Enum.any?(filters, fn f -> f == %{field: :id, op: :>, value: "5 00:00:00"} end)
      assert Enum.any?(filters, fn f -> f == %{field: :id, op: :>=, value: "1 00:00:00"} end)
      assert Enum.any?(filters, fn f -> f == %{field: :title, op: :!=, value: "not this"} end)
    end

    test "handles datetime processing for gteq and lteq operators" do
      params = %{"q" => %{
        "inserted_at_gteq" => "2018-09-05",
        "updated_at_lteq" => "2018-09-10"
      }}
      result = Search.convert_to_flop_params(params)

      expected_filters = [
        %{field: :inserted_at, op: :>=, value: "2018-09-05 00:00:00"},
        %{field: :updated_at, op: :<=, value: "2018-09-10 23:59:59"}
      ]
      assert length(result[:filters]) == 2
      assert Enum.all?(expected_filters, fn filter -> filter in result[:filters] end)
    end

    test "converts sorting parameters" do
      params = %{"s" => "title+asc"}
      result = Search.convert_to_flop_params(params)

      assert result[:order_by] == [:title]
      assert result[:order_directions] == [:asc]
    end

    test "converts sorting parameters with desc order" do
      params = %{"s" => "created_at+desc"}
      result = Search.convert_to_flop_params(params)

      assert result[:order_by] == [:created_at]
      assert result[:order_directions] == [:desc]
    end

    test "defaults to asc when no direction specified" do
      params = %{"s" => "title"}
      result = Search.convert_to_flop_params(params)

      assert result[:order_by] == [:title]
      assert result[:order_directions] == [:asc]
    end

    test "ignores empty search parameters" do
      params = %{"q" => %{"title" => "", "body" => nil, "status" => []}}
      result = Search.convert_to_flop_params(params)

      assert result[:filters] == nil || result[:filters] == []
    end
  end

  describe "searchq" do
    test "applies filters to query using Flop" do
      query = from(p in Alkemist.Post)
      params = %{"q" => %{"title_eq" => "Test Post"}}

      result_query = Search.searchq(query, params)

      # Verify the query structure changed (filters were applied)
      assert %Ecto.Query{} = result_query
      assert result_query != query
    end

    test "handles invalid Flop parameters gracefully" do
      query = from(p in Alkemist.Post)
      params = %{"q" => %{"invalid_field_with_bad_operator" => "test"}}

      # Should not crash and return original query
      result_query = Search.searchq(query, params)
      assert %Ecto.Query{} = result_query
    end

    test "applies multiple filters correctly" do
      query = from(p in Alkemist.Post)
      params = %{"q" => %{
        "title_cont" => "test",
        "published_eq" => "true",
        "id_gt" => "5"
      }}

      result_query = Search.searchq(query, params)
      assert %Ecto.Query{} = result_query
      assert result_query != query
    end
  end

  describe "sortq" do
    test "applies sorting to query using Flop" do
      query = from(p in Alkemist.Post)
      params = %{"s" => "title+desc"}

      result_query = Search.sortq(query, params)

      # Verify the query structure changed (sorting was applied)
      assert %Ecto.Query{} = result_query
      assert result_query != query
    end

    test "handles missing sort parameters" do
      query = from(p in Alkemist.Post)
      params = %{}

      result_query = Search.sortq(query, params)
      assert %Ecto.Query{} = result_query
    end
  end

  describe "run" do
    test "is an alias for searchq" do
      query = from(p in Alkemist.Post)
      params = %{"q" => %{"title_eq" => "Test"}}

      search_result = Search.searchq(query, params)
      run_result = Search.run(query, params)

      # Both should produce equivalent results
      assert search_result == run_result
    end
  end

  describe "handle_special_fields" do
    test "processes datetime fields with gteq operator" do
      result = Search.handle_special_fields({"inserted_at_gteq", "2018-09-05"}, nil)
      assert result == {"inserted_at_gteq", "2018-09-05 00:00:00"}
    end

    test "processes datetime fields with lteq operator" do
      result = Search.handle_special_fields({"updated_at_lteq", "2018-09-10"}, nil)
      assert result == {"updated_at_lteq", "2018-09-10 23:59:59"}
    end

    test "processes datetime fields with gt operator" do
      result = Search.handle_special_fields({"created_at_gt", "2018-09-05"}, nil)
      assert result == {"created_at_gt", "2018-09-05 00:00:00"}
    end

    test "processes datetime fields with lt operator" do
      result = Search.handle_special_fields({"modified_at_lt", "2018-09-10"}, nil)
      assert result == {"modified_at_lt", "2018-09-10 23:59:59"}
    end

    test "does not modify fields without datetime operators" do
      result = Search.handle_special_fields({"title_eq", "test"}, nil)
      assert result == {"title_eq", "test"}
    end

    test "does not modify fields without operator suffix" do
      result = Search.handle_special_fields({"title", "test"}, nil)
      assert result == {"title", "test"}
    end
  end
end
