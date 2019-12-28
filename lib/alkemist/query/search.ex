defmodule Alkemist.Query.Search do
  @moduledoc """
  Implement Basic search functionality. You can define custom search hooks per module
  """

  @empty_values [nil, [], {}, [""], "", %{}]

  def run(query, params) do
    searchq(query, params)
  end

  def searchq(query, params) do
    params =
      params
      |> prepare_params(query)

    Turbo.Ecto.turboq(query, params)
  end

  def sortq(query, params) do
    Turbo.Ecto.turboq(query, params)
  end

  @doc """
  prepares the params so we can better handle naive_datetime and datetime fields
  right now this works not on associations
  """
  def prepare_params(params, query) do
    #queryable = Turbo.Ecto.Utils.schema_from_query(query)

    search_params =
      params
      |> Map.get("q", %{})
      |> Enum.filter(fn {_key, value} -> value not in @empty_values end)
      |> Enum.into(%{})

    Map.put(params, "q", search_params)
  end

end
