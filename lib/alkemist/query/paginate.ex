defmodule Alkemist.Query.Paginate do
  @moduledoc """
  Handles pagination using Flop. Expects to return a tuple with the new query and a map with the following structure:

  ```elixir
  %{
    current_page: 1,
    next_page: 2,
    per_page: 10,
    prev_page: nil,
    total_count: 20,
    total_pages: 2
  }
  ```
  """
  @per_page 10
  import Ecto.Query

  @doc """
  Runs the pagination and returns the new Query and a map with pagination values
  """
  @spec run(Ecto.Query.t(), Map.t(), Keyword.t()) :: {Ecto.Query.t(), Map.t()}
  def run(query, params, opts \\ []) do
    repo = opts[:repo] || raise("Repository must be provided in opts")

    # Convert parameters to Flop format
    flop_params = convert_pagination_params(params)

    case Flop.validate_and_run(query, flop_params, repo: repo) do
      {:ok, {_results, meta}} ->
        # Apply the same filters/sorts to the query without pagination for further processing
        case Flop.query(query, flop_params) do
          {:ok, filtered_query} ->
            pagination = convert_flop_meta_to_alkemist(meta)
            {filtered_query, pagination}
          {:error, _} ->
            pagination = get_pagination_fallback(query, params, opts)
            {query, pagination}
        end

      {:error, _} ->
        pagination = get_pagination_fallback(query, params, opts)
        {query, pagination}
    end
  end

  @doc """
  Convert legacy pagination parameters to Flop format
  """
  defp convert_pagination_params(params) do
    per_page = format_integer(Map.get(params, "per_page", @per_page))
    page = format_integer(Map.get(params, "page", 1))

    %{
      page: page,
      page_size: per_page
    }
  end

  @doc """
  Convert Flop meta to Alkemist expected format
  """
  defp convert_flop_meta_to_alkemist(meta) do
    %{
      current_page: meta.current_page,
      next_page: meta.next_page,
      per_page: meta.page_size,
      prev_page: meta.previous_page,
      total_count: meta.total_count,
      total_pages: meta.total_pages
    }
  end

  @spec get_pagination(Ecto.Query.t(), Map.t(), Keyword.t()) :: Map.t()
  def get_pagination(query, params, opts) do
    params = format_params(params)
    repo = opts[:repo] || Db.Repo
    do_get_paginate(query, params, repo)
  end

  defp format_params(params) do
    params
    |> Map.put_new(:per_page, format_integer(Map.get(params, "per_page", @per_page)))
    |> Map.put_new(:page, format_integer(Map.get(params, "page", 1)))
  end

  @doc """
  Fallback pagination when Flop fails
  """
  defp get_pagination_fallback(query, params, opts) do
    params = format_params(params)
    repo = opts[:repo] || raise("Repository must be provided in opts")
    do_get_paginate(query, params, repo)
  end

  defp do_get_paginate(query, params, repo) do
    per_page = Map.get(params, :per_page)
    total_count = get_total_count(query, repo)

    total_pages =
      total_count
      |> (&(&1 / per_page)).()
      |> Float.ceil()
      |> trunc()

    current_page = Map.get(params, :page)
    next_page = if total_pages - current_page >= 1, do: current_page + 1, else: nil

    prev_page =
      if total_pages >= current_page && current_page > 1, do: current_page - 1, else: nil

    %{
      current_page: current_page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages,
      next_page: next_page,
      prev_page: prev_page
    }
  end

  defp get_total_count(query, repo) do
    query
    |> exclude(:select)
    |> exclude(:preload)
    |> exclude(:order_by)
    |> exclude(:limit)
    |> exclude(:offset)
    |> get_count(repo)
  end

  defp get_count(query, repo) do
    repo.one(from a in query, select: count(a.id))
  end

  defp format_integer(value) when is_integer(value), do: value
  defp format_integer(value) when is_bitstring(value), do: String.to_integer(value)
end
