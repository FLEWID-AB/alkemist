defmodule Alkemist.Query.Search do
  @moduledoc """
  Implement Basic search functionality. You can define custom search hooks per module
  """
  alias Turbo.Ecto.Services.BuildSearchQuery

  @empty_values [nil, [], {}, [""], "", %{}]

  def run(query, params) do
    searchq(query, params) |> Turbo.Ecto.sortq(params)
  end

  def searchq(query, params) do
    params =
      params
      |> prepare_params(query)

    Turbo.Ecto.searchq(query, params)
  end

  def sortq(query, params) do
    Turbo.Ecto.sortq(query, params)
  end

  @doc """
  prepares the params so we can better handle naive_datetime and datetime fields
  right now this works not on associations
  """
  def prepare_params(params, query) do
    queryable = Turbo.Ecto.Utils.schema_from_query(query)

    search_params =
      params
      |> Map.get("q", %{})
      |> Enum.filter(fn {_key, value} -> value not in @empty_values end)
      |> Enum.map(&handle_special_fields(&1, queryable))
      |> Enum.into(%{})

    Map.put(params, "q", search_params)
  end

  def handle_special_fields({key, value}, queryable) do
    regex = ~r/([a-z0-9_]+)_(#{BuildSearchQuery.search_types() |> Enum.join("|")})$/

    {key, value} =
      if Regex.match?(regex, key) do
        [_, match, type] = Regex.run(regex, key)
        value = handle_field({match, type}, value, queryable)
        {key, value}
      else
        {key, value}
      end

    {key, value}
  end

  defp handle_field({match, type}, value, queryable) do
    match = String.to_atom(match)

    if match in queryable.__schema__(:fields) do
      append =
        case type do
          a when a in ["gteq", "gt"] -> " 00:00:00"
          b when b in ["lteq", "lt"] -> " 23:59:59"
          _ -> ""
        end

      case queryable.__schema__(:type, match) do
        a when a in [:naive_datetime, :datetime] ->
          value <> append

        _ ->
          value
      end
    else
      value
    end
  end
end
