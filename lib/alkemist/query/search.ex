defmodule Alkemist.Query.Search do
  @moduledoc """
  This module prepares regular Search Queries. See the Rummage
  documentation for more info.
  In addition to the rummage queries, it allows for :between search types,
  which expect :search_term_start and :search_term_end as parameters.
  """
  @behaviour Rummage.Ecto.Hook

  alias Rummage.Ecto.Services.BuildSearchQuery
  import Ecto.Query

  @doc """
  This method is called to perform the search. See Rummage for additional documentation.
  """
  @spec run(Ecto.Query.t(), map()) :: Ecto.Query.t()
  def run(queryable, rummage) do
    rummage = AtomicMap.convert(rummage, safe: false)
    search_params = Map.get(rummage, :search)

    case search_params do
      a when a in [nil, [], {}, [""], "", %{}] -> queryable
      _ -> handle_search(queryable, search_params)
    end
  end

  def before_hook(_queryable, rummage, _opts), do: rummage

  # Iterate through all search fields and build the query
  defp handle_search(query, search_params) do
    search_params
    |> Map.to_list()
    |> Enum.reduce(query, &search_queryable(&1, &2))
  end

  # Handle the addition for a single search field to the query
  defp search_queryable(param, query) do
    field = elem(param, 0)
    field_params = elem(param, 1)

    assocs =
      case Map.get(field_params, :assoc) do
        a when a in [nil, "", []] -> []
        assoc -> assoc
      end

    search_type = Map.get(field_params, :search_type)

    search_term =
      case search_type do
        "between" -> field_params[:search_term_start] <> field_params[:search_term_end]
        _ -> field_params[:search_term]
      end

    case search_term do
      s when s in [nil, "", []] ->
        query

      _ ->
        query = from(e in subquery(query))

        assocs
        |> Enum.reduce(query, &join_by_association(&1, &2))
        |> build_query(search_type, field, field_params)
    end
  end

  defp build_query(query, "between", field, field_params) do
    search_term_start =
      case Map.get(field_params, :search_term_start) do
        s when s in [nil, "", []] -> nil
        q -> q
      end

    search_term_end =
      case Map.get(field_params, :search_term_end) do
        s when s in [nil, "", []] -> nil
        q -> q
      end

    query =
      if search_term_start != nil do
        query
        |> BuildSearchQuery.run(field, "gteq", search_term_start)
      else
        query
      end

    query =
      if search_term_end != nil do
        BuildSearchQuery.run(query, field, "lteq", search_term_end)
      else
        query
      end

    query
  end

  defp build_query(query, search_type, field, field_params) do
    search_term = Map.get(field_params, :search_term)

    query
    |> BuildSearchQuery.run(field, search_type, search_term)
  end

  # Handles joins
  defp join_by_association(association, queryable) do
    join(queryable, :inner, [..., p1], p2 in assoc(p1, ^String.to_atom(association)))
  end

  @doc """
  Callback implementation for `Rummage.Ecto.Hook.format_params/2`.
  This function ensures that params for each field have keys `assoc`, `search_type` and
  `search_expr` which are essential for running this hook module.
  ## Examples
      iex> alias Rummage.Ecto.Hooks.Search
      iex> Search.format_params(Parent, %{field: %{}}, [])
      %{field: %{assoc: [], search_expr: :where, search_type: :eq}}
  """
  @spec format_params(Ecto.Query.t(), map(), keyword()) :: map()
  def format_params(_queryable, search_params, _opts) do
    search_params
    |> Map.to_list()
    |> Enum.map(&put_keys/1)
    |> Enum.into(%{})
  end

  defp put_keys({field, field_params}) do
    field_params =
      field_params
      |> Map.put_new(:assoc, [])
      |> Map.put_new(:search_type, :eq)
      |> Map.put_new(:search_expr, :where)

    {field, field_params}
  end
end
