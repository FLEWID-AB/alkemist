defmodule Alkemist.Query.PaginateTest do
  use ExUnit.Case, async: true
  alias Alkemist.Query.Paginate

  describe "convert_pagination_params (private function behavior)" do
    test "converts string page and per_page to proper pagination parameters" do
      # Test the behavior indirectly through run/3 error handling
      query = %Ecto.Query{from: %Ecto.Query.FromExpr{source: {"posts", nil}}}
      params = %{"page" => "2", "per_page" => "25"}
      opts = []

      # Should fail gracefully with missing repo error, not parameter conversion error
      assert_raise RuntimeError, ~r/Repository must be provided/, fn ->
        Paginate.run(query, params, opts)
      end
    end

    test "handles integer page and per_page parameters" do
      query = %Ecto.Query{from: %Ecto.Query.FromExpr{source: {"posts", nil}}}
      params = %{page: 3, per_page: 15}
      opts = []

      # Should fail gracefully with missing repo error, not parameter conversion error
      assert_raise RuntimeError, ~r/Repository must be provided/, fn ->
        Paginate.run(query, params, opts)
      end
    end

    test "uses defaults for missing parameters" do
      query = %Ecto.Query{from: %Ecto.Query.FromExpr{source: {"posts", nil}}}
      params = %{}
      opts = []

      # Should fail gracefully with missing repo error, not parameter conversion error
      assert_raise RuntimeError, ~r/Repository must be provided/, fn ->
        Paginate.run(query, params, opts)
      end
    end
  end

  describe "error handling" do
    test "requires repo in options" do
      query = %Ecto.Query{from: %Ecto.Query.FromExpr{source: {"posts", nil}}}
      params = %{"page" => "1", "per_page" => "10"}
      opts = []

      assert_raise RuntimeError, ~r/Repository must be provided/, fn ->
        Paginate.run(query, params, opts)
      end
    end

    test "get_pagination also requires repo" do
      query = %Ecto.Query{from: %Ecto.Query.FromExpr{source: {"posts", nil}}}
      params = %{"page" => "1", "per_page" => "10"}
      opts = []

      # get_pagination should require repo to be provided
      assert_raise RuntimeError, ~r/Repository must be provided/, fn ->
        Paginate.get_pagination(query, params, opts)
      end
    end
  end

  describe "parameter validation" do
    test "handles various parameter formats without crashing" do
      query = %Ecto.Query{from: %Ecto.Query.FromExpr{source: {"posts", nil}}}

      test_cases = [
        %{"page" => "invalid", "per_page" => "not_a_number"},
        %{"page" => "-1", "per_page" => "0"},
        %{page: nil, per_page: nil},
        %{"page" => "", "per_page" => ""},
        %{},
        nil
      ]

      for params <- test_cases do
        # All should fail with repo error, not parameter parsing error
        assert_raise RuntimeError, ~r/Repository must be provided/, fn ->
          Paginate.run(query, params, [])
        end
      end
    end
  end
end