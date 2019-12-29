defmodule Alkemist.Types.Scope do
  @moduledoc """
  Representation of a scope.
  """
  import Ecto.Query, only: [exclude: 2, from: 2]
  alias Alkemist.Utils

  @enforce_keys [:key]

  defstruct [
    :key,
    :label,
    active?: false,
    default?: false,
    count: 0,
    callback: nil
  ]

  @type t :: %__MODULE__{
    key: atom(),
    active?: boolean(),
    default?: boolean(),
    label: String.t() | nil,
    count: non_neg_integer(),
    callback: (Ecto.Query.t() -> Ecto.Query.t()) | nil
  }

  @typep map_opts :: %{
    query: Ecto.Query.t(),
    params: map(),
    repo: module(),
    search_provider: module()
  }

  @doc """
  Creates a new `%Scope{}` struct based on controller configuration and the current query
  """
  @spec map(t() | tuple(), map_opts()) :: t()
  def map(%__MODULE__{} = scope, %{query: query, params: params, repo: repo, search_provider: provider}) do
    query = scope.callback.(query)

    count_query =
      provider.searchq(query, params)
      |> exclude(:limit)
      |> exclude(:order_by)
      |> exclude(:preload)
      |> exclude(:select)
      |> exclude(:order_by)

    count = repo.one(from a in count_query, select: count(a.id))
    current = Map.get(params, "scope")

    scope
    |> Map.put(:count, count)
    |> maybe_add_label()
    |> maybe_set_active(current)
  end

  def map({scope, opts, callback}, search_opts) do
    scope = %__MODULE__{
      key: scope,
      callback: callback,
      label: Keyword.get(opts, :label, Utils.to_label(scope)),
      default?: Keyword.get(opts, :default, false)
    }
    map(scope, search_opts)
  end

  def map({scope, callback}, search_opts) when is_function(callback),
    do: map({scope, [], callback}, search_opts)

  def map({scope, opts}, search_opts),
    do: map({scope, opts, fn q -> q end}, search_opts)


  @doc """
  Maps a list of scopes
  """
  @spec map_all([...], map_opts()) :: [t()]
  def map_all(scopes, search_opts) do
    scopes
    |> Enum.map(& map(&1, search_opts))
  end

  defp maybe_set_active(%__MODULE__{key: key, default?: default} = scope, current_scope) do
    cond do
      is_nil(current_scope) && default ->
        Map.put(scope, :active?, true)

      not is_nil(current_scope) && Atom.to_string(key) == current_scope ->
        Map.put(scope, :active?, true)

      true ->
        Map.put(scope, :active?, false)
    end
  end

  defp maybe_add_label(%__MODULE__{} = scope) do
    label = Map.get(scope, :label, Utils.to_label(scope.key))
    Map.put(scope, :label, label)
  end

  @doc """
  Performs the callback query to limit the result to the one defined in the scope
  """
  @spec scope_query(Ecto.Query.t(), t() | nil) :: Ecto.Query.t()
  def scope_query(query, %__MODULE__{callback: callback}) do
    callback.(query)
  end

  def scope_query(query, _), do: query

  @doc """
  Accepts a list of scopes, finds the active one and applies it to `query`
  """
  @spec scope_by_active(Ecto.Query.t(), [t()]) :: Ecto.Query.t()
  def scope_by_active(query, scopes) do
    scope = Enum.find(scopes, & &1.active? == true)

    scope_query(query, scope)
  end
end
