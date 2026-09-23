defmodule Alkemist.Query.Field do
  @moduledoc """
  A filterable or sortable column, resolved against a schema **by string
  comparison**, never by creating atoms from user input.

  `binding` is `nil` for a column of the root schema, or the association name for
  `<assoc>_assoc_<field>` keys.
  """

  @enforce_keys [:name, :type]
  defstruct [:name, :type, binding: nil, assoc: nil]

  @type t :: %__MODULE__{
          name: atom(),
          type: Ecto.Type.t(),
          binding: atom() | nil,
          assoc: struct() | nil
        }

  @assoc_separator "_assoc_"

  @doc """
  Resolves a field string against a schema. Association fields use the
  `<association>_assoc_<field>` form.

      iex> {:ok, field} = Alkemist.Query.Field.resolve(Alkemist.Post, "title")
      iex> {field.name, field.type, field.binding}
      {:title, :string, nil}

      iex> {:ok, field} = Alkemist.Query.Field.resolve(Alkemist.Post, "category_assoc_name")
      iex> {field.name, field.binding, field.assoc.cardinality}
      {:name, :category, :one}

      iex> Alkemist.Query.Field.resolve(Alkemist.Post, "nope")
      {:error, :unknown_field}
  """
  @spec resolve(module(), String.t()) ::
          {:ok, t()} | {:error, :unknown_field | :unknown_association}
  def resolve(schema, string) when is_atom(schema) and is_binary(string) do
    case String.split(string, @assoc_separator, parts: 2) do
      [assoc_string, field_string] ->
        with {:error, _} <- resolve_assoc(schema, assoc_string, field_string) do
          resolve_root(schema, string)
        end

      [_] ->
        resolve_root(schema, string)
    end
  end

  @doc "The first candidate from `Alkemist.Query.Parser.split/1` that resolves, with its operator."
  @spec resolve_key(module(), String.t()) ::
          {:ok, t(), Alkemist.Query.Parser.operator()} | {:error, :unknown_field}
  def resolve_key(schema, key) do
    key
    |> Alkemist.Query.Parser.split()
    |> Enum.find_value({:error, :unknown_field}, fn {field_string, op} ->
      case resolve(schema, field_string) do
        {:ok, field} -> {:ok, field, op}
        {:error, _} -> nil
      end
    end)
  end

  @doc "The schema an association points at, following `has_through` chains."
  @spec related_schema(struct()) :: module()
  def related_schema(%Ecto.Association.HasThrough{owner: owner, through: through}) do
    Enum.reduce(through, owner, fn step, schema ->
      schema.__schema__(:association, step) |> related_schema()
    end)
  end

  def related_schema(%{related: related}), do: related

  defp resolve_root(schema, string) do
    case find_by_name(schema.__schema__(:fields), string) do
      nil -> {:error, :unknown_field}
      name -> {:ok, %__MODULE__{name: name, type: schema.__schema__(:type, name)}}
    end
  end

  defp resolve_assoc(schema, assoc_string, field_string) do
    with assoc_name when not is_nil(assoc_name) <-
           find_by_name(schema.__schema__(:associations), assoc_string),
         assoc = schema.__schema__(:association, assoc_name),
         related = related_schema(assoc),
         field_name when not is_nil(field_name) <-
           find_by_name(related.__schema__(:fields), field_string) do
      {:ok,
       %__MODULE__{
         name: field_name,
         type: related.__schema__(:type, field_name),
         binding: assoc_name,
         assoc: assoc
       }}
    else
      nil -> {:error, :unknown_association}
    end
  end

  defp find_by_name(atoms, string), do: Enum.find(atoms, &(Atom.to_string(&1) == string))
end
