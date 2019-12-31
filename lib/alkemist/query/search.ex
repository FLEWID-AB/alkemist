defmodule Alkemist.Query.Search do
  @moduledoc """
  Implement Basic search functionality. You can define custom search hooks per module
  """
  import Ecto.Query, only: [exclude: 2]
  @empty_values [nil, [], {}, [""], "", %{}]

  def run(query, params) do
    query
    |> searchq(params)
  end

  def searchq(query, params) do
    params =
      params
      |> prepare_params(query)


    query
    |> Turbo.Ecto.turboq(params)
    |> exclude(:limit)
    |> exclude(:offset)
  end

  @doc """
  prepares the params so we can better handle naive_datetime and datetime fields
  right now this works not on associations
  """
  def prepare_params(params, _query) do
    #queryable = Turbo.Ecto.Utils.schema_from_query(query)

    search_params =
      params
      |> Map.get("q", %{})
      |> Enum.filter(fn {_key, value} -> value not in @empty_values end)
      |> Enum.into(%{})

    params
    |> Map.put("q", search_params)
    |> Map.take(["q", "s"])
  end

end
