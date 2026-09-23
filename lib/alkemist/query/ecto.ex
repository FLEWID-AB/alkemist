defmodule Alkemist.Query.Ecto do
  @moduledoc """
  Applies `Alkemist.Query.Filter`s and sorts to an `Ecto.Query`.

  Root filters become `where` clauses. Filters on cardinality-one associations
  (`belongs_to`, `has_one`) add one named left join per association. Filters on
  cardinality-many associations (`has_many`, `many_to_many`, `has_through`) become a
  semi-join, `where pk in subquery(...)`, so the root row count is never inflated.
  """
  import Ecto.Query
  alias Alkemist.Query.{Field, Filter}

  @root_alias :alkemist_root

  @doc "Applies filters to the query."
  @spec apply_filters(Ecto.Queryable.t(), [Filter.t()]) :: Ecto.Query.t()
  def apply_filters(queryable, filters) do
    {query, root} = root_binding(queryable)

    {root_filters, assoc_filters} = Enum.split_with(filters, &is_nil(&1.field.binding))

    query = Enum.reduce(root_filters, query, &where(&2, ^condition(&1, root)))

    assoc_filters
    |> Enum.group_by(& &1.field.binding)
    |> Enum.reduce(query, fn {_name, group}, q -> apply_assoc_group(q, group, root) end)
  end

  @doc "Applies one sort to the query, joining a cardinality-one association if needed."
  @spec apply_sort(Ecto.Queryable.t(), Field.t(), Alkemist.Query.Sort.direction()) ::
          Ecto.Query.t()
  def apply_sort(queryable, %Field{binding: nil, name: name}, direction) do
    {query, root} = root_binding(queryable)
    order_by(query, [{^root, r}], [{^direction, field(r, ^name)}])
  end

  def apply_sort(queryable, %Field{binding: binding, name: name} = field, direction) do
    {query, _root} = root_binding(queryable)

    query
    |> ensure_join(field)
    |> order_by([{^binding, a}], [{^direction, field(a, ^name)}])
  end

  @doc """
  Guarantees the root source has a named binding and returns `{query, alias}`. A query
  whose `from` is already aliased keeps its alias.
  """
  @spec root_binding(Ecto.Queryable.t()) :: {Ecto.Query.t(), atom()}
  def root_binding(queryable) do
    query = Ecto.Queryable.to_query(queryable)

    case query.from.as do
      nil -> {from(q in query, as: ^@root_alias), @root_alias}
      existing -> {query, existing}
    end
  end

  defp apply_assoc_group(
         query,
         [%Filter{field: %Field{assoc: %{cardinality: :one}}} | _] = group,
         _root
       ) do
    [%Filter{field: %Field{assoc: assoc, binding: binding} = field} | _] = group
    _ = assoc

    query = ensure_join(query, field)
    Enum.reduce(group, query, &where(&2, ^condition(&1, binding)))
  end

  defp apply_assoc_group(query, [%Filter{field: %Field{assoc: assoc}} | _] = group, root) do
    owner = assoc.owner
    {pk, _type} = Alkemist.Schema.primary_key!(owner)

    sub =
      from(o in owner,
        join: r in assoc(o, ^assoc.field),
        as: :alkemist_assoc,
        select: field(o, ^pk)
      )

    sub = Enum.reduce(group, sub, &where(&2, ^condition(&1, :alkemist_assoc)))

    where(query, [{^root, r}], field(r, ^pk) in subquery(sub))
  end

  defp ensure_join(query, %Field{binding: binding}) do
    if has_named_binding?(query, binding) do
      query
    else
      {query, root} = root_binding(query)
      join(query, :left, [{^root, r}], a in assoc(r, ^binding), as: ^binding)
    end
  end

  # Builds the dynamic condition for a filter on the given named binding.
  defp condition(%Filter{field: %Field{name: name}, op: op, value: value}, binding) do
    case op do
      :eq ->
        dynamic([{^binding, r}], field(r, ^name) == ^value)

      :neq ->
        dynamic([{^binding, r}], field(r, ^name) != ^value)

      :lt ->
        dynamic([{^binding, r}], field(r, ^name) < ^value)

      :lteq ->
        dynamic([{^binding, r}], field(r, ^name) <= ^value)

      :gt ->
        dynamic([{^binding, r}], field(r, ^name) > ^value)

      :gteq ->
        dynamic([{^binding, r}], field(r, ^name) >= ^value)

      :in ->
        dynamic([{^binding, r}], field(r, ^name) in ^value)

      :not_in ->
        dynamic([{^binding, r}], field(r, ^name) not in ^value)

      :cont ->
        dynamic(
          [{^binding, r}],
          ilike(type(field(r, ^name), :string), ^("%" <> escape(value) <> "%"))
        )

      :not_cont ->
        dynamic(
          [{^binding, r}],
          not ilike(type(field(r, ^name), :string), ^("%" <> escape(value) <> "%"))
        )

      :start ->
        dynamic([{^binding, r}], ilike(type(field(r, ^name), :string), ^(escape(value) <> "%")))

      :not_start ->
        dynamic(
          [{^binding, r}],
          not ilike(type(field(r, ^name), :string), ^(escape(value) <> "%"))
        )

      :end ->
        dynamic([{^binding, r}], ilike(type(field(r, ^name), :string), ^("%" <> escape(value))))

      :not_end ->
        dynamic(
          [{^binding, r}],
          not ilike(type(field(r, ^name), :string), ^("%" <> escape(value)))
        )

      :null ->
        if value,
          do: dynamic([{^binding, r}], is_nil(field(r, ^name))),
          else: dynamic([{^binding, r}], not is_nil(field(r, ^name)))

      :not_null ->
        if value,
          do: dynamic([{^binding, r}], not is_nil(field(r, ^name))),
          else: dynamic([{^binding, r}], is_nil(field(r, ^name)))

      :not_within ->
        {from, to} = value
        dynamic([{^binding, r}], field(r, ^name) < ^from or field(r, ^name) >= ^to)
    end
  end

  @doc false
  # Escapes LIKE metacharacters so user input matches literally.
  def escape(value), do: Regex.replace(~r/[\\%_]/, value, "\\\\\\0")
end
