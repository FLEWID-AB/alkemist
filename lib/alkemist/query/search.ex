defmodule Alkemist.Query.Search do
  @moduledoc """
  Default `Alkemist.Query.SearchProvider`.

  Reads `params["q"]` (filters, see `Alkemist.Query.Parser`) and `params["s"]` (sort,
  see `Alkemist.Query.Sort`), resolves them against the schema by name and applies
  them with `Alkemist.Query.Ecto`. Unknown fields and uncastable values are ignored;
  their keys (never their values) are logged at debug level.
  """
  @behaviour Alkemist.Query.SearchProvider

  require Logger
  alias Alkemist.Query.{Ecto, Filter, Sort}

  @impl true
  def run(queryable, params, opts \\ []) do
    queryable
    |> filter(params, opts)
    |> sort(params, opts)
  end

  @impl true
  def filter(queryable, params, opts \\ []) do
    schema = Alkemist.Schema.from_queryable(queryable, opts)
    {filters, ignored} = Filter.parse_all(schema, params["q"], opts)

    if ignored != [] do
      Logger.debug(fn ->
        "alkemist: ignored filter keys #{inspect(ignored)} for #{inspect(schema)}"
      end)
    end

    Ecto.apply_filters(queryable, filters)
  end

  @impl true
  def sort(queryable, params, opts \\ []) do
    schema = Alkemist.Schema.from_queryable(queryable, opts)
    sort_param = params["s"]

    case Sort.parse(schema, sort_param) do
      {:ok, field, direction} ->
        Ecto.apply_sort(queryable, field, direction)

      {:error, reason} ->
        if is_binary(sort_param) do
          Logger.debug(fn -> "alkemist: ignored sort #{inspect(sort_param)} (#{reason})" end)
        end

        queryable
    end
  end

  @deprecated "Use filter/3"
  def searchq(queryable, params), do: filter(queryable, params, [])

  @deprecated "Use sort/3"
  def sortq(queryable, params), do: sort(queryable, params, [])
end
