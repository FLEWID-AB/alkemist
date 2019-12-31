defmodule Alkemist.Assign.Export do
  @moduledoc """
  Creates the View assigns for the export controller action
  """
  alias Alkemist.{Assign.Global, Utils, Config, Types.Scope, Types.Column}
  @since "2.0.0"
  @behaviour Alkemist.Assign

  @doc """
  Ensures that all required values are available during the export

  ### Params
  * `params` - the request params that were passed to the controller action (search, scope, etc)
  * `resource` - the struct to query (an Ecto.Schema definition)
  * `opts` - Keyword list with options (see below)

  ### Options
  * `repo` - custom `Ecto.Repo`
  * `search_provider` - custom search module
  * `columns` - the columns to display in the export, default is the columns definition from the controller
  * `preload` - an `Ecto.Query`-compatible list of associations to preload
  * `query` - use a custom `type:Ecto.Query.t` as the base query
  """
  @impl Alkemist.Assign
  def assigns(resource, opts, params) do
    opts = default_opts(opts, resource)
    scopes = Scope.map_all(opts[:scopes], %{query: opts[:query], params: params, repo: opts[:repo], search_provider: opts[:search_provider]})

    query =
      opts[:query]
      |> Scope.scope_by_active(scopes)
      |> opts[:search_provider].run(params)

    columns =
      opts[:columns]
      |> Enum.map(& Column.map(&1, resource))

    entries =
      query
      |> Global.preload(Keyword.get(opts, :preload))
      |> opts[:repo].all()

    [
      entries: entries,
      columns: columns
    ]
  end

  @doc """
  creates a list of the default options that need to be available during export
  """
  @impl Alkemist.Assign
  def default_opts(opts, resource) do
    opts
    |> Global.opts(resource)
    |> Keyword.put_new(:query, resource)
    |> Keyword.put_new_lazy(:columns, fn -> Utils.display_fields(resource) end)
    |> Keyword.put_new(:scopes, [])
    |> Keyword.put_new(:search_provider, Config.search_provider(opts[:alkemist_app], opts[:implementation]))
  end
end
