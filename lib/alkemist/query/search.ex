defmodule Alkemist.Query.Search do
  @moduledoc """
  Implement Basic search functionality using Flop. You can define custom search hooks per module
  """

  @empty_values [nil, [], {}, [""], "", %{}]

  def run(query, params) do
    searchq(query, params)
  end

  def searchq(query, params) do
    flop_params = convert_to_flop_params(params)

    # Create a proper Flop struct
    case Flop.validate(flop_params) do
      {:ok, flop} -> Flop.query(query, flop)
      {:error, _} -> query
    end
  end

  def sortq(query, params) do
    flop_params = convert_to_flop_params(params)

    # Create a proper Flop struct
    case Flop.validate(flop_params) do
      {:ok, flop} -> Flop.query(query, flop)
      {:error, _} -> query
    end
  end

  @doc """
  Convert legacy turbo_ecto style parameters to Flop format
  """
  def convert_to_flop_params(params) do
    # Start with a clean map containing only Flop-compatible keys
    %{}
    |> add_search_filters(params)
    |> add_sort_params(params)
  end

  defp add_search_filters(flop_params, params) do
    search_params =
      params
      |> Map.get("q", %{})
      |> prepare_search_filters_with_datetime()

    if Enum.empty?(search_params) do
      flop_params
    else
      filters = Enum.map(search_params, fn {field, value, op} ->
        %{field: field, op: op, value: value}
      end)
      Map.put(flop_params, :filters, filters)
    end
  end

  defp add_sort_params(flop_params, params) do
    case params |> Map.get("s") do
      nil -> flop_params
      sort_string ->
        case parse_sort_string(sort_string) do
          {field, direction} ->
            flop_params
            |> Map.put(:order_by, [field])
            |> Map.put(:order_directions, [direction])
          _ -> flop_params
        end
    end
  end

  defp parse_sort_string(sort_string) do
    case String.split(sort_string, "+") do
      [field, "desc"] -> {String.to_atom(field), :desc}
      [field, "asc"] -> {String.to_atom(field), :asc}
      [field] -> {String.to_atom(field), :asc}
      _ -> nil
    end
  end

  defp prepare_search_filters_with_datetime(search_params) do
    search_params
    |> Enum.filter(fn {_key, value} -> value not in @empty_values end)
    |> Enum.map(&parse_search_field/1)
    |> Enum.filter(& &1)
  end

  defp parse_search_field({key, value}) do
    # Check if this is a turbo_ecto style field with operator suffix
    regex = ~r/^(.+)_(eq|neq|lt|lteq|gt|gteq|in|cont|not_cont|start|not_start|end|not_end)$/

    case Regex.run(regex, key) do
      [_, field_name, operator] ->
        field_atom = String.to_atom(field_name)
        flop_op = map_turbo_operator_to_flop(operator)
        processed_value = process_datetime_value(operator, value)
        {field_atom, processed_value, flop_op}

      nil ->
        # Default field without operator suffix - use ilike for string matching
        field_atom = String.to_atom(key)
        {field_atom, value, :ilike_and}
    end
  end

  defp map_turbo_operator_to_flop(operator) do
    case operator do
      "eq" -> :==
      "neq" -> :!=
      "lt" -> :<
      "lteq" -> :<=
      "gt" -> :>
      "gteq" -> :>=
      "in" -> :in
      "cont" -> :ilike_and
      "not_cont" -> :not_ilike_and
      "start" -> :like_and
      "not_start" -> :not_like_and
      "end" -> :like_and
      "not_end" -> :not_like_and
      _ -> :ilike_and
    end
  end

  defp process_datetime_value(operator, value) when is_binary(value) do
    append =
      case operator do
        op when op in ["gteq", "gt"] -> " 00:00:00"
        op when op in ["lteq", "lt"] -> " 23:59:59"
        _ -> ""
      end

    value <> append
  end

  defp process_datetime_value(_operator, value), do: value

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
      |> Enum.map(&handle_special_fields(&1, query))
      |> Enum.into(%{})

    Map.put(params, "q", search_params)
  end

  def handle_special_fields({key, value}, _queryable) do
    # Extract operator from key and apply datetime processing if needed
    regex = ~r/^(.+)_(eq|neq|lt|lteq|gt|gteq|in|cont|not_cont|start|not_start|end|not_end)$/

    case Regex.run(regex, key) do
      [_, _field_name, operator] ->
        processed_value = process_datetime_value(operator, value)
        {key, processed_value}
      nil ->
        {key, value}
    end
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
