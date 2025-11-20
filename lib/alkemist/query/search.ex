defmodule Alkemist.Query.Search do
  @moduledoc """
  Implement Basic search functionality using Flop. You can define custom search hooks per module
  """

  @empty_values [nil, [], {}, [""], "", %{}]

  def run(query, params) do
    searchq(query, params)
  end

  def searchq(query, params) do
    # First apply any association-based filters manually
    query_with_assoc_filters = apply_association_filters(query, params)
    
    # Then apply regular Flop filters (excluding association fields)
    flop_params = convert_to_flop_params_excluding_associations(params)

    # Create a proper Flop struct
    case Flop.validate(flop_params) do
      {:ok, flop} -> Flop.query(query_with_assoc_filters, flop, [])
      {:error, _} -> query_with_assoc_filters
    end
  end

  def sortq(query, params) do
    flop_params = convert_to_flop_params(params)

    # Create a proper Flop struct
    case Flop.validate(flop_params) do
      {:ok, flop} -> Flop.query(query, flop, [])
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

  @doc """
  Convert to Flop params but exclude association fields that need manual handling
  """
  def convert_to_flop_params_excluding_associations(params) do
    %{}
    |> add_search_filters_excluding_associations(params)
    |> add_sort_params(params)
  end

  @doc """
  Apply association-based filters manually with proper joins
  """
  def apply_association_filters(query, params) do
    import Ecto.Query
    
    search_params =
      params
      |> Map.get("q", %{})
      |> prepare_search_filters_with_datetime()
    
    # Group association filters by association name to minimize joins
    association_filters = 
      search_params
      |> Enum.filter(fn 
        {{:assoc, _, _}, _, _} -> true
        _ -> false
      end)
      |> Enum.group_by(fn {{:assoc, assoc, _}, _, _} -> assoc end)
    
    # Apply each association's filters
    Enum.reduce(association_filters, query, fn {assoc_name, filters}, acc_query ->
      # Add join for this association
      joined_query = ensure_association_join(acc_query, assoc_name)
      
      # Apply all filters for this association
      Enum.reduce(filters, joined_query, fn {{:assoc, ^assoc_name, field}, value, op}, q ->
        apply_association_filter(q, assoc_name, field, value, op)
      end)
    end)
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

  defp add_search_filters_excluding_associations(flop_params, params) do
    search_params =
      params
      |> Map.get("q", %{})
      |> prepare_search_filters_with_datetime()
      |> Enum.reject(fn 
        {{:assoc, _, _}, _, _} -> true
        _ -> false
      end)

    if Enum.empty?(search_params) do
      flop_params
    else
      filters = Enum.map(search_params, fn {field, value, op} ->
        %{field: field, op: op, value: value}
      end)
      Map.put(flop_params, :filters, filters)
    end
  end

  defp ensure_association_join(query, assoc_name) do
    import Ecto.Query
    
    # Check if association is already joined
    joins = query.joins || []
    has_join = Enum.any?(joins, fn
      %{source: {_, _}, as: ^assoc_name} -> true
      %{assoc: {_, ^assoc_name}} -> true
      _ -> false
    end)
    
    if has_join do
      query
    else
      # Add left join with named binding
      join(query, :left, [root], assoc in assoc(root, ^assoc_name), as: ^assoc_name)
    end
  end

  defp apply_association_filter(query, assoc_name, field, value, op) do
    import Ecto.Query
    
    # Convert Flop operators to Ecto query conditions
    condition = case op do
      :== -> 
        dynamic([{^assoc_name, assoc}], field(assoc, ^field) == ^value)
      :!= -> 
        dynamic([{^assoc_name, assoc}], field(assoc, ^field) != ^value)
      :> -> 
        dynamic([{^assoc_name, assoc}], field(assoc, ^field) > ^value)
      :>= -> 
        dynamic([{^assoc_name, assoc}], field(assoc, ^field) >= ^value)
      :< -> 
        dynamic([{^assoc_name, assoc}], field(assoc, ^field) < ^value)
      :<= -> 
        dynamic([{^assoc_name, assoc}], field(assoc, ^field) <= ^value)
      :ilike_and -> 
        value_with_wildcards = "%#{value}%"
        dynamic([{^assoc_name, assoc}], ilike(field(assoc, ^field), ^value_with_wildcards))
      :not_ilike_and -> 
        value_with_wildcards = "%#{value}%"
        dynamic([{^assoc_name, assoc}], not ilike(field(assoc, ^field), ^value_with_wildcards))
      _ -> 
        # Fallback to equality
        dynamic([{^assoc_name, assoc}], field(assoc, ^field) == ^value)
    end
    
    where(query, ^condition)
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
        # Check if this is an association field (contains underscore pattern like "association_field")
        case parse_association_field(field_name) do
          {assoc, field} ->
            # This is an association field like "subscriber_personal_number_hash"
            flop_op = map_turbo_operator_to_flop(operator)
            processed_value = process_datetime_value(operator, value)
            # Return special format for association fields
            {{:assoc, assoc, field}, processed_value, flop_op}
          
          nil ->
            # Regular field
            field_atom = String.to_atom(field_name)
            flop_op = map_turbo_operator_to_flop(operator)
            processed_value = process_datetime_value(operator, value)
            {field_atom, processed_value, flop_op}
        end

      nil ->
        # Default field without operator suffix - use ilike for string matching
        field_atom = String.to_atom(key)
        {field_atom, value, :ilike_and}
    end
  end

  # Parse association fields using the pattern "schema_assoc_field" -> {:schema, :field}
  # Example: "subscriber_assoc_personal_number_hash" -> {:subscriber, :personal_number_hash}
  defp parse_association_field(field_name) do
    # List of common association patterns - could be made configurable
    associations = ["subscriber", "subscription"]
    
    Enum.find_value(associations, fn assoc ->
      # Only handle "_assoc_" pattern for clear separation
      if String.starts_with?(field_name, assoc <> "_assoc_") do
        field_part = String.replace_prefix(field_name, assoc <> "_assoc_", "")
        # Make sure we have a valid field name after the prefix
        if field_part != "" do
          {String.to_atom(assoc), String.to_atom(field_part)}
        end
      end
    end)
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
    case parse_datetime_string(value) do
      {:ok, naive_datetime} ->
        case operator do
          op when op in ["gteq", "gt"] ->
            # For >= or >, set time to beginning of day if only date provided
            if has_time_component?(value) do
              naive_datetime
            else
              %{naive_datetime | hour: 0, minute: 0, second: 0, microsecond: {0, 0}}
            end
          op when op in ["lteq", "lt"] ->
            # For <= or <, set time to end of day if only date provided
            if has_time_component?(value) do
              naive_datetime
            else
              %{naive_datetime | hour: 23, minute: 59, second: 59, microsecond: {999_999, 6}}
            end
          _ ->
            naive_datetime
        end
      {:error, _} ->
        # If parsing fails, return the original value
        value
    end
  end

  defp process_datetime_value(_operator, value), do: value

  defp has_time_component?(value) do
    String.contains?(value, [" ", "T"]) and String.contains?(value, ":")
  end

  defp parse_datetime_string(value) do
    cond do
      # Try full datetime format first (YYYY-MM-DD HH:MM:SS)
      Regex.match?(~r/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/, value) ->
        NaiveDateTime.from_iso8601(String.replace(value, " ", "T"))
      
      # Try datetime without seconds (YYYY-MM-DD HH:MM)
      Regex.match?(~r/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/, value) ->
        NaiveDateTime.from_iso8601(String.replace(value, " ", "T") <> ":00")
      
      # Try date only format (YYYY-MM-DD)
      Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, value) ->
        NaiveDateTime.from_iso8601(value <> "T00:00:00")
      
      # Try ISO format (YYYY-MM-DDTHH:MM:SS)
      Regex.match?(~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/, value) ->
        NaiveDateTime.from_iso8601(value)
      
      true ->
        {:error, :invalid_format}
    end
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
