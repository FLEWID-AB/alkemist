defmodule Alkemist.Types.Column do
  @moduledoc """
  Representation of a column.

  This module also provides helper functions to create columns from their controller
  definition.
  """
  alias Alkemist.Utils

  defstruct [
    :label,
    :field,
    :callback,
    :sort_field,
    :type,
    :assoc,
    sortable?: false,
    class: "",
    opts: %{}
  ]

  @type t :: %__MODULE__{
    label: String.t() | nil,
    field: atom() | nil,
    callback: (struct() -> any()) | nil,
    sort_field: atom() | nil,
    type: atom() | nil,
    assoc: atom() | nil,
    sortable?: boolean(),
    class: String.t(),
    opts: map()
  }

  @sortable_types ~w(string integer float date datetime naive_datetime)a

  @doc """
  Populates the column with default data

  ## Examples

    iex> Alkemist.Types.Column.map(:title, Post)
    %Alkemist.Types.Column{field: :title, label: "Title", sortable?: true, sort_field: :title, type: :string}

    iex> Alkemist.Types.Column.map({"Category", %{assoc: :category, field: :name, class: "custom", custom_option: "foo"}}, Post)
    %Alkemist.Types.Column{field: :name, assoc: :category, label: "Category", sort_field: :category_name, type: :string, sortable?: true, class: "custom", opts: %{custom_option: "foo"}}

    iex> Alkemist.Types.Column.map(%{field: :title}, Post)
    %Alkemist.Types.Column{field: :title, label: "Title", sort_field: :title, sortable?: true, type: :string}

  You can also create custom columns with a callback

    Alkemist.Types.Column.map({"Custom Title", fn row -> row.title end}, Post)
    > %Alkemist.Types.Column{label: "Custom Title", callback: fn row -> row.title end}
  """
  @spec map(t() | atom() | tuple(), map() | module()) :: t()
  def map(%__MODULE__{} = column, resource) do
    column
    |> set_label()
    |> set_type_from_resource(resource)
    |> maybe_make_sortable()
    |> maybe_transform_assoc(resource)
    |> set_default_callback()
  end

  def map(params, resource) when is_map(params) do
    keys = Map.keys(%__MODULE__{})
    struct_params = Map.take(params, keys)
    new_opts = Map.drop(params, keys)
    struct =
      __MODULE__
      |> struct!(struct_params)

    map(Map.put(struct, :opts, Map.merge(struct.opts, new_opts)), resource)
  end

  def map({field, callback, opts}, resource) when is_atom(field) do
    opts =
      opts
      |> Map.put(:field, field)
      |> Map.put(:callback, callback)

    map(opts, resource)
  end

  def map({field, callback, opts}, resource) when is_bitstring(field) do
    opts =
      opts
      |> Map.put(:label, field)
      |> Map.put(:callback, callback)

    map(opts, resource)
  end

  def map({field, callback}, resource) when is_function(callback),
    do: map({field, callback, %{}}, resource)


  def map({field, opts}, resource) when is_map(opts),
    do: map({field, nil, opts}, resource)

  def map(field, resource) when is_atom(field),
    do: map({field, nil, %{}}, resource)


  # Provide a default callback when it is not set in the column
  defp set_default_callback(%{callback: _callback} = column) do
    column
  end

  defp set_default_callback(%{assoc: assoc, field: field} = column) do
    callback = fn row ->
      row
      |> Map.get(assoc)
      |> Map.get(field)
    end

    Map.put(column, :callback, callback)
  end

  defp set_default_callback(%{field: field} = column) do
    callback = fn row ->
      Map.get(row, field)
    end

    Map.put(column, :callback, callback)
  end

  defp set_default_callback(column) do
    Map.put(column, :callback, fn _ -> "" end)
  end

  # set the label of the field if we do not have it
  defp set_label(%{label: label} = col) when is_bitstring(label), do: col

  defp set_label(col) do
    Map.put(col, :label, Utils.to_label(col.field))
  end

  # Set the type of the column if it is auto-generated
  defp set_type_from_resource(%{field: field} = col, resource) do
    col
    |> Map.put(:type, Utils.get_field_type(field, resource))
  end

  defp set_type_from_resource(col, _), do: col

  # check if we can sort by this field if it is an auto-generated column
  defp maybe_make_sortable(%{field: field, type: type} = col) when type in @sortable_types do
    field = if col.assoc, do: String.to_atom("#{col.assoc}_#{field}"), else: field
    col
    |> Map.put(:sortable?, true)
    |> Map.put(:sort_field, field)
  end

  defp maybe_make_sortable(col), do: col

  # see if we are dealing with an association
  defp maybe_transform_assoc(%{assoc: assoc} = col, resource) when is_atom(:assoc) do
    struct =
      if is_map(resource) do
        resource.__struct__
      else
        resource
      end

    assoc = if assoc in struct.__schema__(:associations) do
      struct.__schema__(:association, assoc)
    else
      nil
    end

    if is_nil(assoc) do
      col
    else
      col
      |> Map.put(:assoc, assoc.field)
      |> Map.put_new(:field, :id)
    end
  end

  defp maybe_transform_assoc(col, _), do: col
end
