defmodule Alkemist.Assign.Index do
  @moduledoc """
  Generates the default assigns for the Controller's index view.
  """
  alias Alkemist.{Utils, Assign.Global, Config}
  #TODO: create a type and defstruct for options here so we can work with a map

  @doc """
  Creates the default assigns for a controller index action.
  Params:
    * params - the controller route params
    * resource - the resource module
    * opts - a KeywordList with options

  Opts:
    * otp_app - otp application, default: `:alkemist`
    * implementation - the main implementation module, default: `Alkemist`
    * repo - the Ecto.Repo to use for the lookup
    * query - an Ecto.Query. By default, the resource will be used
    * preload - list of associations to preload
    * collection_actions - global actions (without ID)
    * member_actions - actions available for a single resource
    * singular_name - Label for a single resource. By default the singular of the db table is used
    * plural_name - Pluralized name for labels. By default this is the db table name
    * search_provider - Provide a custom module for your search, default: `Alkemist.Query.Search`
    * scopes - a list of scopes with callback functions
    * columns - list of columns to display
    * pagination_provider - pagination module to use, default: `Alkemist.Query.Paginate`
    * filters - list of filters to display
    * batch_actions: list of batch actions
    * sort_by - default sort for this view, default 'id+desc'
  """
  @since "2.0.0"
  def assigns(params, resource, opts \\ [])
  def assigns(params, resource, opts) do
    opts = default_opts(opts, resource)
    repo = opts[:repo]
    params =
      params
      |> Utils.clean_params()
      |> Map.put_new("s", opts[:sort_by])

    query = opts[:query]

    # TODO: implement scopes module

  end

  # Create default options
  defp default_opts(opts, resource) do
    opts = Global.opts(opts, resource)

    opts
    |> Keyword.put_new(:query, resource)
    |> Keyword.put_new(:columns, []) # TODO: default columns
    |> Keyword.put_new(:scopes, [])
    |> Keyword.put_new(:filters, [])
    |> Keyword.put_new(:show_aside, Keyword.has_key?(opts, :sidebars))
    |> Keyword.put_new(:search_provider, Config.search_provider(opts[:alkemist_app], opts[:implementation]))
    |> Keyword.put_new(:pagination_provider, Config.pagination_provider(opts[:alkemist_app], opts[:implementation]))
    |> Keyword.put_new(:mod, resource)
    |> Keyword.put_new(:batch_actions, [])
    |> Keyword.put_new(:sidebars, [])
    |> Keyword.put_new(:sort_by, "id+desc")
  end
end
