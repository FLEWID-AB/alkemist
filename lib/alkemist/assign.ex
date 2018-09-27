defmodule Alkemist.Assign do
  @moduledoc """
  Provides helper functions for generic CRUD assigns
  """
  import Ecto.Query
  alias Alkemist.Utils

  @default_collection_actions [:new]
  @default_member_actions [
    :edit,
    :delete
  ]
  @default_action_opts [
    show: [icon: "fas fa-fw fa-eye"],
    edit: [icon: "fas fa-fw fa-edit"],
    delete: [
      icon: "fas fa-fw fa-trash",
      link_opts: [method: :delete, data: [confirm: "Do you really want to delete this record?"]]
    ]
  ]
  @default_search_provider Alkemist.Config.search_provider()
  @default_pagination_provider Alkemist.Config.pagination_provider()

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
    * search_provider - Provide a custom module for your search
  """
  def index_assigns(params, resource, opts \\ []) do
    opts = default_index_opts(opts, resource)
    repo = opts[:repo]
    params = Utils.clean_params(params)

    query = opts[:query]

    scopes =
      opts[:scopes]
      |> Enum.map(fn scope ->
        map_scope(scope, query, params, opts)
      end)

    query = query |> scope(scopes)

    columns =
      opts[:columns]
      |> maybe_add_selectable(opts[:batch_actions])
      |> Enum.map(fn col -> map_column(col, resource) end)

    query = opts[:search_provider].run(query, params)
    {query, pagination} = opts[:pagination_provider].run(query, params, repo: repo)
    entries =
      query
      |> do_preload(opts[:preload])
      |> repo.all()

    [
      struct: Utils.get_struct(resource),
      resource: resource,
      entries: entries,
      pagination: pagination,
      columns: columns,
      scopes: scopes,
      filters: opts[:filters],
      sidebars: opts[:sidebars],
      batch_actions: opts[:batch_actions],
      show_aside: opts[:show_aside],
      search: Map.has_key?(params, "q"),
      mod: opts[:mod]
    ]
    |> global_assigns(opts)
    |> additional_assigns(opts)
  end

  defp global_assigns(assigns, opts) do
    global_opts = [
      member_actions: member_actions(opts),
      collection_actions: collection_actions(opts),
      singular_name: opts[:singular_name],
      plural_name: opts[:plural_name]
    ]

    Keyword.merge(assigns, global_opts)
  end

  defp member_actions(opts) do
    opts[:member_actions]
    |> Enum.map(&__MODULE__.format_action(&1, opts[:singular_name]))
  end

  defp collection_actions(opts) do
    opts[:collection_actions]
    |> Enum.map(&__MODULE__.format_action(&1, opts[:singular_name]))
  end

  defp maybe_add_selectable(columns, batch_actions) do
    if Enum.empty?(batch_actions) do
      columns
    else
      if Keyword.has_key?(columns, :selectable_column) || :selectable_column in columns do
        columns
      else
        [:selectable_column | columns]
      end
    end
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
        map_scope(scope, query, params, opts)
      end)

    query = query |> scope(scopes)

    columns =
      opts[:columns]
      |> Enum.map(fn col -> map_column(col, resource) end)

    query = opts[:search_provider].run(query, params)

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
        map_form_fields(opts[:fields], [], resource, opts)
      else
        []
      end

    [
      struct: Utils.get_struct(resource),
      changeset: changeset,
      resource: changeset.data,
      mod: opts[:mod],
      form_partial: opts[:form_partial],
      form_fields: fields
    ]
    |> global_assigns(opts)
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
      |> do_preload_resource(opts[:preload])

    [
      struct: Utils.get_struct(struct),
      resource: resource,
      mod: resource.__struct__,
      rows: rows,
      panels: Keyword.get(opts, :show_panels, [])
    ]
    |> global_assigns(opts)
    |> additional_assigns(opts)
  end

  defp global_opts(opts, resource) do
    opts
    |> Keyword.put_new(:repo, Alkemist.Config.repo())
    |> Keyword.put_new(:collection_actions, @default_collection_actions)
    |> Keyword.put_new(:member_actions, @default_member_actions)
    |> Keyword.put_new(:singular_name, Utils.singular_name(resource))
    |> Keyword.put_new(:plural_name, Utils.plural_name(resource))
  end

  defp default_index_opts(opts, resource) do
    opts = global_opts(opts, resource)
    show_aside = Keyword.has_key?(opts, :sidebars)

    opts
    |> Keyword.put_new(:query, resource)
    |> Keyword.put_new(:columns, get_default_columns(resource))
    |> Keyword.put_new(:scopes, [])
    |> Keyword.put_new(:filters, [])
    |> Keyword.put_new(:show_aside, show_aside)
    |> Keyword.put_new(:search_provider, @default_search_provider)
    |> Keyword.put_new(:pagination_provider, @default_pagination_provider)
    |> Keyword.put_new(:mod, resource)
    |> Keyword.put_new(:batch_actions, [])
    |> Keyword.put_new(:sidebars, [])
  end

  defp default_csv_opts(opts, resource) do
    opts = global_opts(opts, resource)

    opts
    |> Keyword.put_new(:query, resource)
    |> Keyword.put_new(:columns, get_default_columns(resource))
    |> Keyword.put_new(:scopes, [])
    |> Keyword.put_new(:search_provider, @default_search_provider)
  end

  # Preloads any data
  defp generate_changeset(_resource, opts) do
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
    opts = global_opts(opts, resource)

    opts =
      opts
      |> Keyword.put_new(:changeset, resource.changeset(resource.__struct__, %{}))
      |> Keyword.put_new(:resource, resource)
      |> Keyword.put_new(:mod, resource.__struct__)

    if Keyword.has_key?(opts, :form_partial) do
      {partial, assigns} =
        case Keyword.get(opts, :form_partial) do
          {mod, template, assigns} -> {{mod, template}, assigns}
          {mod, template} -> {{mod, template}, []}
        end

      if Enum.empty?(assigns) do
        Keyword.put(opts, :form_partial, partial)
      else
        assigns = Keyword.merge(Keyword.get(opts, :assigns, []), assigns)

        opts
        |> Keyword.put(:form_partial, partial)
        |> Keyword.put(:assigns, assigns)
      end
    else
      opts
      |> Keyword.put_new(:fields, get_default_form_fields(resource))
      |> Keyword.put(:form_partial, {AlkemistView, "form.html"})
    end
  end

  defp default_show_opts(opts, resource) do
    opts = global_opts(opts, resource)

    opts
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

  defp do_preload_resource(resource, preloads) do
    if preloads == nil do
      resource
    else
      resource |> Alkemist.Config.repo().preload(preloads)
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

  defp check_for_assoc(opts, resource) do
    struct =
      if is_map(resource) do
        resource.__struct__
      else
        resource
      end

    unless Map.has_key?(opts, :field), do: opts = Map.put(opts, :field, :id)
    # check for assoc & field opts
    assoc =
      cond do
        Map.has_key?(opts, :assoc) and opts.assoc in struct.__schema__(:associations) ->
          struct.__schema__(:association, opts.assoc)

        Map.has_key?(opts, :col) and opts.col in struct.__schema__(:associations) ->
          struct.__schema__(:association, opts.col)

        true ->
          nil
      end

    if is_nil(assoc) do
      opts
    else
      opts |> Map.put(:resource, assoc.queryable) |> Map.put(:assoc, assoc.field)
    end
  end

  # Creates an Enum of field and callback
  defp map_column({field, callback, opts}, resource) when is_atom(field) do
    opts =
      Map.put(opts, :type, get_field_type(field, resource))
      |> check_for_assoc(resource)

    {field, callback, opts}
  end

  defp map_column({field, callback}, resource)
       when is_bitstring(field) and is_function(callback) do
    map_column({nil, callback, %{label: field}}, resource)
  end

  defp map_column({field, opts}, resource) when is_bitstring(field) and is_map(opts) do
    opts =
      opts
      |> Map.put(:label, field)
      |> check_for_assoc(resource)

    map_column(
      {nil,
       fn row ->
         default_callback(opts, row, field)
       end, opts},
      resource
    )
  end

  defp map_column({field, callback, opts}, resource) when is_bitstring(field) and is_map(opts) do
    opts =
      opts
      |> Map.put(:label, field)
      |> check_for_assoc(resource)

    map_column({nil, callback, opts}, resource)
  end

  defp map_column({field, callback}, resource) when is_atom(field) and is_function(callback) do
    label = Utils.to_label(field)

    opts =
      %{label: label, col: field}
      |> check_for_assoc(resource)

    map_column({field, callback, opts}, resource)
  end

  defp map_column({field, opts}, resource) when is_atom(field) and is_map(opts) do
    opts =
      Map.put_new(opts, :label, Utils.to_label(field))
      |> Map.put_new(:col, field)
      |> check_for_assoc(resource)

    map_column({field, fn row -> default_callback(opts, row, field) end, opts}, resource)
  end

  defp map_column(field, resource) do
    opts = %{field: field} |> check_for_assoc(resource)
    map_column({field, fn row -> default_callback(opts, row, field) end}, resource)
  end

  defp default_callback(opts, row, field) do
    if is_association?(opts) do
      Map.get(row, opts.assoc) |> Map.get(opts.field)
    else
      Map.get(row, field)
    end
  end

  defp is_association?(opts) do
    Map.has_key?(opts, :resource)
  end

  defp map_form_fields([field | tail], results, resource, opts) when is_map(field) do
    fields =
      Map.get(field, :fields, [])
      |> Enum.map(fn f -> map_form_field(f, resource) end)
      |> filter_fields()

    results = results ++ [Map.put(field, :fields, fields)]
    map_form_fields(tail, results, resource, opts)
  end

  defp map_form_fields([field | tail], results, resource, opts) do
    group =
      if Enum.empty?(results) do
        %{title: "#{opts[:singular_name]} Details", fields: []}
      else
        Enum.at(results, 0)
      end

    field = map_form_field(field, resource)

    fields =
      (Map.get(group, :fields, []) ++ [field])
      |> filter_fields()

    results = [Map.put(group, :fields, fields)]

    map_form_fields(tail, results, resource, opts)
  end

  defp map_form_fields([], results, _resource, _opts), do: results

  defp map_form_field({field, opts}, resource) do
    opts =
      opts
      |> Map.put_new(:type, get_field_type(field, resource))

    {field, opts}
  end

  defp map_form_field(field, resource) do
    map_form_field({field, %{}}, resource)
  end

  defp filter_fields(fields) do
    Enum.filter(fields, fn {_f, opts} ->
      Map.get(opts, :type) != :embed
    end)
  end

  # Returns the type of a given field. Default is :string. This is used for tables
  defp get_field_type(field, resource) when is_map(resource),
    do: get_field_type(field, resource.__struct__)

  defp get_field_type(field, resource) do
    case resource.__schema__(:type, field) do
      val when val in [:boolean, :integer, :date, :datetime, :float] -> val
      {:embed, _} -> :embed
      :id -> :select
      _ -> :string
    end
  end

  # normalizes the scopes and retrieves the scope counts
  defp map_scope({scope, opts, callback}, query, params, search_opts) do
    query =
      query
      |> callback.()
      |> search_opts[:search_provider].run(params)

    {query, pagination} = search_opts[:pagination_provider].run(query, params, repo: search_opts[:repo])

    current = Map.get(params, "scope")

    opts =
      opts
      |> Keyword.put_new(:label, Utils.to_label(scope))
      |> Keyword.put(:count, Map.get(pagination, :total_count, 0))

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
      label = Utils.to_label("#{action} #{opts[:singular_name]}")
      {action, Keyword.put(opts, :label, label)}
    end
  end

  def format_action({action, opts}, singular) do
    opts = case Keyword.get(@default_action_opts, action) do
      nil -> opts
      default -> Keyword.merge(default, opts)
    end
    opts = if singular do
      Keyword.put(opts, :singular_name, singular)
    else
      opts
    end
    format_action({action, opts})
  end

  def format_action(action, singular) when is_atom(action) do

    format_action({action, []}, singular)
  end
end
