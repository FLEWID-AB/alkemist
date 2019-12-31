defmodule Alkemist.Assign do
  @moduledoc """
  Provides helper functions for generic CRUD assigns
  """
  alias Alkemist.{Utils, Types.Scope, Types.Column}

  @default_search_provider Alkemist.Config.search_provider()

  @doc """
  Creates the default assigns for a controller index action.
  """
  @deprecated "Use Alkemist.Assign.Index.assigns/3 instead"
  def index_assigns(params, resource, opts \\ []) do
    Alkemist.Assign.Index.assigns(params, resource, opts)
  end

  @doc """
  Creates all the necessary values for the CSV generation
  """
  def csv_assigns(params, resource, opts \\ []) do
    opts = default_csv_opts(opts, resource)
    repo = opts[:repo]

    query = opts[:query]

    scopes = Scope.map_all(opts[:scopes], %{query: query, params: params, repo: repo, search_provider: opts[:search_provider]})

    query = query |> Scope.scope_by_active(scopes)

    columns =
      opts[:columns]
      |> Enum.map(& Column.map(&1, resource))

    query = opts[:search_provider].run(query, params)

    entries =
      query
      |> Alkemist.Assign.Global.preload(Keyword.get(opts, :preload))
      |> repo.all()

    [
      entries: entries,
      columns: columns
    ]
  end

  @doc """
  Creates the view assigns for the new and edit actions
  """
  @deprecated "Use `Alkemist.Assign.Form.assigns/2` instead"
  def form_assigns(resource, opts \\ []) do
    Alkemist.Assign.Form.assigns(resource, opts)
  end

  @doc """
  Creates the assigns for the show view
  """
  @deprecated "Use `Alkemist.Assign.Show.assigns/2` instead"
  def show_assigns(resource, opts \\ []) do
    Alkemist.Assign.Show.assigns(resource, opts)
  end

  defp default_csv_opts(opts, resource) do
    opts = Alkemist.Assign.Global.opts(opts, resource)

    opts
    |> Keyword.put_new(:query, resource)
    |> Keyword.put_new(:columns, Utils.display_fields(resource))
    |> Keyword.put_new(:scopes, [])
    |> Keyword.put_new(:search_provider, @default_search_provider)
  end

end
