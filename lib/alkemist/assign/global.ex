defmodule Alkemist.Assign.Global do
  @moduledoc """
  Creates global assigns based on defaults and options
  """

  @doc """
  Builds a `Keyword` List with global options that need to be available on all pages

  Params:

    * opts - KeywordList with options
    * resource - a Struct or Ecto Struct module
  """

  alias Alkemist.{Utils, Types.Action, Config}
  import Ecto.Query, only: [from: 2]

  def opts(opts, implementation, resource) do
    opts =
      opts
      |> Keyword.put_new(:implementation, implementation)

    opts
    |> Keyword.put_new(:repo, implementation.config(:repo))
    |> Keyword.put_new(:collection_actions, Action.default_collection_actions)
    |> Keyword.put_new(:member_actions, Action.default_member_actions)
    |> Keyword.put_new(:singular_name, Utils.singular_name(resource))
    |> Keyword.put_new(:plural_name, Utils.plural_name(resource))
    |> Keyword.put_new(:route_params, [])
  end

  @doc """
  Global assigns that should exist on every controller action
  """
  @spec assigns(keyword()) :: keyword()
  def assigns(opts) do
    [
      member_actions: Action.map_all(opts[:member_actions], :member),
      collection_actions: Action.map_all(opts[:collection_actions], :collection)
    ]
    |> Keyword.put_new(:title, Config.get(:title, opts[:implementation]))
    |> Keyword.put_new(:logo, Config.get(:logo, opts[:implementation]))
    |> Keyword.merge(Keyword.take(opts, [:implementation, :route_params, :singular_name, :plural_name]))
  end

  @doc """
  Preloads `preloads` within a query
  """
  @spec preload(Ecto.Query.t(), keyword() | nil) :: Ecto.Query.t()
  def preload(query, preloads) when is_nil(preloads), do: query
  def preload(query, preloads) do
    from(r in query, preload: ^preloads)
  end
end
