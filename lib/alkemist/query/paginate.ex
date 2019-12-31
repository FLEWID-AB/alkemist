defmodule Alkemist.Query.Paginate do
  @moduledoc """
  Handles pagination. Expects to return a tuple with the new query and a map with the following structure:

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
    params = Map.take(params, ["per_page", "page"])
    query = Turbo.Ecto.turboq(query, params)
    pagination = get_pagination(query, params, opts)
    {query, pagination}
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
