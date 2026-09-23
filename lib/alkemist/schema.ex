defmodule Alkemist.CompositePrimaryKeyError do
  @moduledoc "Raised when a schema with a composite primary key is used where Alkemist needs a single key."
  defexception [:schema, :primary_key]

  @impl true
  def message(%{schema: schema, primary_key: pk}) do
    "Alkemist requires a single primary key, but #{inspect(schema)} has #{inspect(pk)}"
  end
end

defmodule Alkemist.Schema do
  @moduledoc """
  Reflection helpers over Ecto schemas used throughout Alkemist.
  """

  @doc """
  Returns `{field, type}` of the schema's single primary key.

  Raises `ArgumentError` when the schema has no primary key and
  `Alkemist.CompositePrimaryKeyError` when it has more than one.
  """
  @spec primary_key!(module()) :: {atom(), Ecto.Type.t()}
  def primary_key!(schema) do
    case primary_key(schema) do
      {:ok, pk} ->
        pk

      {:error, :none} ->
        raise ArgumentError, "#{inspect(schema)} has no primary key"

      {:error, :composite} ->
        raise Alkemist.CompositePrimaryKeyError,
          schema: schema,
          primary_key: schema.__schema__(:primary_key)
    end
  end

  @doc "Like `primary_key!/1` but returns `{:ok, {field, type}}` or `{:error, :none | :composite}`."
  @spec primary_key(module()) :: {:ok, {atom(), Ecto.Type.t()}} | {:error, :none | :composite}
  def primary_key(schema) do
    case schema.__schema__(:primary_key) do
      [pk] -> {:ok, {pk, schema.__schema__(:type, pk)}}
      [] -> {:error, :none}
      _ -> {:error, :composite}
    end
  end

  @doc """
  Finds the schema module behind a queryable: a schema module, an `Ecto.Query`
  whose source is a schema, or `opts[:schema]` for subqueries and fragments.
  """
  @spec from_queryable(Ecto.Queryable.t(), keyword()) :: module()
  def from_queryable(queryable, opts \\ [])

  def from_queryable(%Ecto.Query{from: %{source: {_table, schema}}}, _opts)
      when is_atom(schema) and not is_nil(schema),
      do: schema

  def from_queryable(schema, _opts) when is_atom(schema) and not is_nil(schema) do
    if schema?(schema) do
      schema
    else
      raise ArgumentError, "#{inspect(schema)} is not an Ecto schema"
    end
  end

  def from_queryable(_queryable, opts) do
    opts[:schema] ||
      raise ArgumentError,
            "could not derive the schema from the query; pass `schema: MySchema` in the options"
  end

  @doc "True when the module is a compiled Ecto schema."
  @spec schema?(term()) :: boolean()
  def schema?(module) when is_atom(module) and not is_nil(module) do
    Code.ensure_loaded?(module) and function_exported?(module, :__schema__, 1)
  end

  def schema?(_), do: false

  @doc """
  The default sort string for a schema, `"<primary key>+desc"`, or `nil` when it has no
  single primary key.
  """
  @spec default_sort(module()) :: String.t() | nil
  def default_sort(schema) do
    case primary_key(schema) do
      {:ok, {pk, _type}} -> "#{pk}+desc"
      _ -> nil
    end
  end
end
