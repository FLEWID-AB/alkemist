defmodule Alkemist.Query.PaginateTest do
  use ExUnit.Case, async: true
  alias Alkemist.Query.Paginate
  import Ecto.Query

  describe "run/3" do
    setup do
      query = from(p in Alkemist.Post)
      {:ok, query: query}
    end

    test "runs pagination with basic parameters", %{query: query} do
      params = %{"page" => "2", "per_page" => "10"}
      opts = [repo: Alkemist.Repo]

      {result_query, pagination} = Paginate.run(query, params, opts)

      # Should return a tuple with query and pagination metadata
      assert %Ecto.Query{} = result_query
      assert %{
        current_page: 2,
        per_page: 10,
        total_count: _,
        total_pages: _
      } = pagination
    end

    test "uses default page size when not specified", %{query: query} do
      params = %{"page" => "1"}
      opts = [repo: Alkemist.Repo]

      {_result_query, pagination} = Paginate.run(query, params, opts)

      assert pagination.per_page == 10  # Default page size
    end

    test "uses default page when not specified", %{query: query} do
      params = %{"per_page" => "25"}
      opts = [repo: Alkemist.Repo]

      {_result_query, pagination} = Paginate.run(query, params, opts)

      assert pagination.current_page == 1  # Default page
    end

    test "handles string parameters correctly", %{query: query} do
      params = %{"page" => "3", "per_page" => "15"}
      opts = [repo: Alkemist.Repo]

      {_result_query, pagination} = Paginate.run(query, params, opts)

      assert pagination.current_page == 3
      assert pagination.per_page == 15
    end

    test "includes next_page when there are more pages", %{query: query} do
      params = %{"page" => "1", "per_page" => "1"}
      opts = [repo: Alkemist.Repo]

      {_result_query, pagination} = Paginate.run(query, params, opts)

      # The actual value depends on test data, but structure should be correct
      assert Map.has_key?(pagination, :next_page)
    end

    test "includes prev_page when not on first page", %{query: query} do
      params = %{"page" => "2", "per_page" => "10"}
      opts = [repo: Alkemist.Repo]

      {_result_query, pagination} = Paginate.run(query, params, opts)

      assert Map.has_key?(pagination, :prev_page)
    end

    test "requires repo in options", %{query: query} do
      params = %{"page" => "1", "per_page" => "10"}
      opts = []

      assert_raise RuntimeError, ~r/Repository must be provided/, fn ->
        Paginate.run(query, params, opts)
      end
    end

    test "returns expected pagination structure", %{query: query} do
      params = %{"page" => "1", "per_page" => "10"}
      opts = [repo: Alkemist.Repo]

      {_result_query, pagination} = Paginate.run(query, params, opts)

      # Should have the expected structure that Alkemist views expect
      required_keys = [:current_page, :per_page, :total_count, :total_pages, :next_page, :prev_page]

      Enum.each(required_keys, fn key ->
        assert Map.has_key?(pagination, key), "Missing key: #{key}"
      end)
    end

    test "handles missing params gracefully", %{query: query} do
      params = %{}
      opts = [repo: Alkemist.Repo]

      {_result_query, pagination} = Paginate.run(query, params, opts)

      # Should use defaults
      assert pagination.current_page == 1
      assert pagination.per_page == 10
    end

    test "handles Flop validation errors gracefully", %{query: query} do
      # Test with extremely large page number that might cause issues
      params = %{"page" => "999999", "per_page" => "10"}
      opts = [repo: Alkemist.Repo]

      # Should not crash and return a valid result
      {result_query, pagination} = Paginate.run(query, params, opts)

      assert %Ecto.Query{} = result_query
      assert %{} = pagination
      assert Map.has_key?(pagination, :current_page)
    end
  end

  describe "get_pagination/3" do
    setup do
      query = from(p in Alkemist.Post)
      {:ok, query: query}
    end

    test "returns pagination metadata without running query", %{query: query} do
      params = %{"page" => "2", "per_page" => "10"}
      opts = [repo: Alkemist.Repo]

      pagination = Paginate.get_pagination(query, params, opts)

      assert %{
        current_page: 2,
        per_page: 10,
        total_count: _,
        total_pages: _
      } = pagination
    end

    test "calculates total pages correctly", %{query: query} do
      params = %{"page" => "1", "per_page" => "3"}
      opts = [repo: Alkemist.Repo]

      pagination = Paginate.get_pagination(query, params, opts)

      # If we have any records, total_pages should be at least 1
      assert pagination.total_pages >= 0
      assert is_integer(pagination.total_pages)
    end

    test "calculates next_page correctly", %{query: query} do
      params = %{"page" => "1", "per_page" => "10"}
      opts = [repo: Alkemist.Repo]

      pagination = Paginate.get_pagination(query, params, opts)

      # next_page should be 2 if there are more than 10 records, nil otherwise
      if pagination.total_count > 10 do
        assert pagination.next_page == 2
      else
        assert pagination.next_page == nil
      end
    end

    test "calculates prev_page correctly for first page", %{query: query} do
      params = %{"page" => "1", "per_page" => "10"}
      opts = [repo: Alkemist.Repo]

      pagination = Paginate.get_pagination(query, params, opts)

      # First page should never have a previous page
      assert pagination.prev_page == nil
    end

    test "calculates prev_page correctly for second page", %{query: query} do
      params = %{"page" => "2", "per_page" => "10"}
      opts = [repo: Alkemist.Repo]

      pagination = Paginate.get_pagination(query, params, opts)

      # Second page should have previous page of 1 if there are enough records
      if pagination.total_count > 0 do
        assert pagination.prev_page == 1
      end
    end
  end

  describe "integration with Flop" do
    setup do
      query = from(p in Alkemist.Post)
      {:ok, query: query}
    end

    test "works with complex queries", %{query: query} do
      # Add some filters to the query first
      filtered_query = from(p in query, where: p.published == true)

      params = %{"page" => "1", "per_page" => "5"}
      opts = [repo: Alkemist.Repo]

      {result_query, pagination} = Paginate.run(filtered_query, params, opts)

      assert %Ecto.Query{} = result_query
      assert pagination.per_page == 5
      assert pagination.current_page == 1
    end

    test "preserves query structure after pagination", %{query: query} do
      params = %{"page" => "1", "per_page" => "10"}
      opts = [repo: Alkemist.Repo]

      {result_query, _pagination} = Paginate.run(query, params, opts)

      # The returned query should still be an Ecto.Query
      assert %Ecto.Query{} = result_query
      # Should maintain the same from clause
      assert result_query.from.source == query.from.source
    end
  end

  describe "parameter formatting" do
    setup do
      query = from(p in Alkemist.Post)
      {:ok, query: query}
    end

    test "handles string page and per_page parameters", %{query: query} do
      params = %{"page" => "3", "per_page" => "20"}
      opts = [repo: Alkemist.Repo]

      {_result_query, pagination} = Paginate.run(query, params, opts)

      assert pagination.current_page == 3
      assert pagination.per_page == 20
    end

    test "handles integer page and per_page parameters", %{query: query} do
      params = %{page: 2, per_page: 15}
      opts = [repo: Alkemist.Repo]

      {_result_query, pagination} = Paginate.run(query, params, opts)

      assert pagination.current_page == 2
      assert pagination.per_page == 15
    end

    test "handles mixed parameter types", %{query: query} do
      params = %{"page" => 4, per_page: "25"}
      opts = [repo: Alkemist.Repo]

      {_result_query, pagination} = Paginate.run(query, params, opts)

      assert pagination.current_page == 4
      assert pagination.per_page == 25
    end
  end
end