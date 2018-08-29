defmodule Manager.Assign do
  @moduledoc """
  Provides helper functions for generic CRUD assigns
  """
  import Ecto.Query
  alias Manager.Utils

  # TODO: move into config
  @default_collection_actions [:new]
  @default_member_actions [
    show: [icon: "fas fa-fw fa-eye"],
    edit: [icon: "fas fa-fw fa-edit"],
    delete: [
      icon: "fas fa-fw fa-trash",
      link_opts: [method: :delete, data: [confirm: "Do you really want to delete this record?"]]
    ]
  ]
  @default_search_hook Manager.DefaultSearchHook

  @doc """
  Creates the default assigns for a controller index action.
  Params:
    * params - the controller route params
    * resource - the resource module
    * opts - a KeywordList with options

  Opts:
    * repo - the Ecto.Repo to use for the lookup
    * query - an Ecto.Query. By default, the resource will be used
    * preload - list of associations to preload
    * collection_actions - global actions (without ID)
    * member_actions - actions available for a single resource
    * singular_name - Label for a single resource. By default the singular of the db table is used
    * plural_name - Pluralized name for labels. By default this is the db table name
  """
  def index_assigns(params, resource, opts \\ []) do
    opts = default_index_opts(opts, resource)
    repo = opts[:repo]

    query = opts[:query]

    scopes =
      opts[:scopes]
      |> Enum.map(fn scope ->
        map_scope(scope, query, params, repo: repo, search: opts[:search_hook])
      end)

    query = query |> scope(scopes)

    collection_actions =
      opts[:collection_actions]
      |> Enum.map(&__MODULE__.format_action/1)

    member_actions =
      opts[:member_actions]
      |> Enum.map(&__MODULE__.format_action/1)

    columns =
      opts[:columns]
      |> Enum.map(fn col -> map_column(col, resource) end)

    {query, rummage} =
      query
      |> Rummage.Ecto.rummage(params["rummage"], repo: repo, search: opts[:search_hook])

    entries =
      query
      |> do_preload(opts[:preload])
      |> repo.all()

    [
      struct: Utils.get_struct(resource),
      entries: entries,
      rummage: rummage,
      columns: columns,
      member_actions: member_actions,
      collection_actions: collection_actions,
      singular_name: opts[:singular_name],
      plural_name: opts[:plural_name],
      scopes: scopes,
      filters: opts[:filters],
      show_aside: opts[:show_aside],
      mod: opts[:mod]
    ]
    |> additional_assigns(opts)
  end

  @doc """
  Creates all the necessary values for the CSV generation
  """
  def csv_assigns(params, resource, opts \\ []) do
    opts = default_csv_opts(opts, resource)
    repo = opts[:repo]

    query = opts[:query]

    scopes =
      opts[:scopes]
      |> Enum.map(fn scope ->
        map_scope(scope, query, params, repo: repo, search: opts[:search])
      end)

    query = query |> scope(scopes)

    columns =
      opts[:columns]
      |> Enum.map(fn col -> map_column(col, resource) end)

    {query, _rummage} =
      query
      |> Rummage.Ecto.rummage(
        params["rummage"],
        repo: repo,
        paginate: false,
        search: opts[:search_hook]
      )

    entries =
      query
      |> do_preload(opts[:preload])
      |> repo.all()

    [
      entries: entries,
      columns: columns
    ]
  end

  @doc """
  Creates the view assigns for the new and edit actions
  """
  def form_assigns(resource, opts \\ []) do
    opts = default_form_opts(opts, resource)
    changeset = generate_changeset(resource, opts)

    fields =
      if opts[:fields] do
        opts[:fields]
        |> Enum.map(fn f -> map_form_field(f, resource) end)
      else
        []
      end

    [
      struct: Utils.get_struct(resource),
      changeset: changeset,
      resource: changeset.data,
      mod: opts[:mod],
      form_partial: opts[:form_partial],
      form_fields: fields,
      singular_name: opts[:singular_name]
    ]
    |> additional_assigns(opts)
  end

  @doc """
  Creates the assigns for the show view
  Params:
    * resource - a single entry from the DB
  """
  def show_assigns(resource, opts \\ []) do
    struct = resource.__struct__
    opts = default_show_opts(opts, struct)

    rows =
      opts[:rows]
      |> Enum.map(fn col -> map_column(col, resource) end)

    resource =
      resource
      |> do_preload(opts[:preload])

    [
      struct: Utils.get_struct(struct),
      resource: resource,
      mod: resource.__struct__,
      rows: rows,
      singular_name: opts[:singular_name],
      panels: Keyword.get(opts, :panels, [])
    ]
    |> additional_assigns(opts)
  end

  defp default_index_opts(opts, resource) do
    show_aside = Keyword.has_key?(opts, :filters)

    opts
    |> Keyword.put_new(:repo, Manager.Config.repo())
    |> Keyword.put_new(:query, resource)
    |> Keyword.put_new(:collection_actions, @default_collection_actions)
    |> Keyword.put_new(:member_actions, @default_member_actions)
    |> Keyword.put_new(:columns, get_default_columns(resource))
    |> Keyword.put_new(:singular_name, Utils.singular_name(resource))
    |> Keyword.put_new(:plural_name, Utils.plural_name(resource))
    |> Keyword.put_new(:scopes, [])
    |> Keyword.put_new(:filters, [])
    |> Keyword.put_new(:show_aside, show_aside)
    |> Keyword.put_new(:search_hook, @default_search_hook)
    |> Keyword.put_new(:mod, resource)
  end

  defp default_csv_opts(opts, resource) do
    opts
    |> Keyword.put_new(:repo, Manager.Config.repo())
    |> Keyword.put_new(:query, resource)
    |> Keyword.put_new(:columns, get_default_columns(resource))
    |> Keyword.put_new(:scopes, [])
    |> Keyword.put_new(:search_hook, @default_search_hook)
  end

  # Preloads any data
  defp generate_changeset(resource, opts) do
    case opts[:preload] do
      nil ->
        opts[:changeset]

      preloads ->
        changeset = opts[:changeset]

        data =
          changeset.data
          |> opts[:repo].preload(preloads)

        Map.put(changeset, :data, data)
    end
  end

  # Adds any additional assigns to the assign KeywordList
  # Those can be passed with [assigns: [key: "value"]]
  defp additional_assigns(assigns, opts) do
    case opts[:assigns] do
      nil ->
        assigns

      values ->
        Enum.reduce(values, assigns, fn {k, v}, assigns ->
          Keyword.put(assigns, k, v)
        end)
    end
  end

  defp default_form_opts(opts, resource) do
    opts =
      opts
      |> Keyword.put_new(:changeset, resource.changeset(resource.__struct__, %{}))
      |> Keyword.put_new(:resource, resource)
      |> Keyword.put_new(:singular_name, Utils.singular_name(resource))
      |> Keyword.put_new(:repo, Manager.Config.repo())
      |> Keyword.put_new(:mod, resource.__struct__)

    if Keyword.get(opts, :form_partial) do
      Keyword.put(opts, :form_partial, opts[:form_partial])
    else
      opts
      |> Keyword.put_new(:fields, get_default_form_fields(resource))
      |> Keyword.put(:form_partial, {ManagerView, "form.html"})
    end
  end

  defp default_show_opts(opts, resource) do
    opts
    |> Keyword.put_new(:repo, Manager.Config.repo())
    |> Keyword.put_new(:singular_name, Utils.singular_name(resource))
    |> Keyword.put_new(:rows, get_default_columns(resource))
    |> Keyword.put_new(:resource, resource)
  end

  # Add preloads to the query if any are given
  defp do_preload(query, preloads) do
    if preloads == nil do
      query
    else
      from(r in query, preload: ^preloads)
    end
  end

  # Creates a List with the default columns to display
  def get_default_columns(resource) do
    Enum.reduce(resource.__schema__(:fields), [], fn f, columns ->
      case f do
        :inserted_at -> columns
        :updated_at -> columns
        _ -> columns ++ [f]
      end
    end)
  end

  # Compiles a list of the default form fields
  defp get_default_form_fields(resource) do
    Enum.reduce(resource.__schema__(:fields), [], fn f, columns ->
      case f do
        a when a in [:inserted_at, :updated_at, :id] -> columns
        _ -> columns ++ [f]
      end
    end)
  end

  # Creates an Enum of field and callback
  defp map_column({field, callback, opts}, resource) when is_atom(field) do
    opts = Keyword.put(opts, :type, get_field_type(field, resource))
    {field, callback, opts}
  end

  defp map_column({field, callback}, resource) when is_bitstring(field) do
    map_column({nil, callback, [label: field]}, resource)
  end

  defp map_column({field, callback}, resource) when is_atom(field) and is_function(callback) do
    label = Utils.to_label(field)

    map_column({field, callback, [label: label]}, resource)
  end

  defp map_column({field, opts}, resource) when is_atom(field) and is_list(opts) do
    opts = Keyword.put_new(opts, :label, Utils.to_label(field))
    map_column({field, fn row -> Map.get(row, field) end, opts}, resource)
  end

  defp map_column(field, resource) do
    map_column({field, fn row -> Map.get(row, field) end}, resource)
  end

  defp map_form_field({field, opts}, resource) do
    opts =
      opts
      |> Keyword.put_new(:type, get_field_type(field, resource))

    {field, opts}
  end

  defp map_form_field(field, resource) do
    map_form_field({field, []}, resource)
  end

  # Returns the type of a given field. Default is :string. This is used for tables
  defp get_field_type(field, resource) when is_map(resource),
    do: get_field_type(field, resource.__struct__)

  defp get_field_type(field, resource) do
    case resource.__schema__(:type, field) do
      val when val in [:boolean, :integer, :date, :datetime, :float] -> val
      _ -> :string
    end
  end

  # normalizes the scopes and retrieves the scope counts
  defp map_scope({scope, opts, callback}, query, params, rummage_opts) do
    {query, rummage} =
      query
      |> callback.()
      |> Rummage.Ecto.rummage(params["rummage"], rummage_opts)

    current = Map.get(params, "scope")

    opts =
      opts
      |> Keyword.put_new(:label, Utils.to_label(scope))
      |> Keyword.put(:count, rummage["paginate"]["total_count"])

    opts =
      cond do
        current != nil && "#{scope}" == current -> Keyword.put(opts, :active, true)
        current == nil && opts[:default] == true -> Keyword.put(opts, :active, true)
        true -> Keyword.put(opts, :active, false)
      end

    {scope, opts, callback}
  end

  defp map_scope({scope, opts}, query, repo),
    do: map_scope({scope, opts, fn q -> q end}, query, params, repo)

  defp map_scope(scope, query, repo), do: map_scope({scope, []}, query, params, repo)

  # Merges the scope callback into the query
  defp scope(query, scopes) do
    current = Enum.find(scopes, fn {_s, opts, _cb} -> opts[:active] == true end)

    if current != nil do
      {_s, _opts, cb} = current
      query |> cb.()
    else
      query
    end
  end

  # Creates a {action, opts} struct for each member action
  def format_action({action, opts} = params) do
    if Keyword.get(opts, :label) do
      params
    else
      label = Utils.to_label(action)
      {action, Keyword.put(opts, :label, label)}
    end
  end

  def format_action(action), do: format_action({action, []})
end
