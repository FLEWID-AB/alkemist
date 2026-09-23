defmodule Alkemist.Query do
  @moduledoc """
  Shared query helpers used by the search and pagination providers.
  """
  import Ecto.Query

  @doc """
  Counts the rows a query would return, ignoring its ordering, preloads, selection,
  limit and offset. Queries with `distinct` or `group_by` are counted through a
  subquery so the count stays correct.

  Uses `COUNT(*)`, so it makes no assumption about a primary key column.
  """
  @spec count(Ecto.Queryable.t(), module()) :: non_neg_integer()
  def count(queryable, repo) do
    base =
      queryable
      |> Ecto.Queryable.to_query()
      |> exclude(:order_by)
      |> exclude(:preload)
      |> exclude(:select)
      |> exclude(:limit)
      |> exclude(:offset)

    count_query =
      if base.distinct != nil or base.group_bys != [] do
        from(s in subquery(select(base, [r], %{__alkemist_row__: 1})), select: count())
      else
        from(r in base, select: count())
      end

    repo.one(count_query) || 0
  end
end
