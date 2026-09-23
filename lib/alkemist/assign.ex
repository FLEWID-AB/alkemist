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
    new: [icon: "hero-plus"],
    show: [icon: "hero-eye"],
    edit: [icon: "hero-pencil-square"],
    delete: [
      icon: "hero-trash",
      link_opts: [method: :delete, data: [confirm: "Do you really want to delete this record?"]]
    ]
  ]
  @sortable_types ~w(string integer float number date datetime)a

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
    params = params |> Utils.clean_params() |> put_default_sort(opts[:sort_by])

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
      |> Enum.map(fn {field, cb, column_opts} ->
        column_opts = Map.put(column_opts, :route_params, opts[:route_params])
        {field, cb, column_opts}
      end)

    provider_opts = provider_opts(opts, resource)
    query = opts[:search_provider].run(query, params, provider_opts)
    {query, pagination} = opts[:pagination_provider].run(query, params, provider_opts)

    entries =
      query
      |> do_preload(opts[:preload])
      |> repo.all()

    filters = Enum.map(opts[:filters], &normalize_filter/1)
    q = params["q"]

    [
      struct: opts[:struct] || Utils.get_struct(resource),
      resource: resource,
      entries: entries,
      pagination: pagination,
      columns: columns,
      scopes: scopes,
      filters: filters,
      filter_form: Phoenix.Component.to_form(if(is_map(q), do: q, else: %{}), as: :q),
      page_description: opts[:description],
      sort: parse_sort(params["s"]),
      link_params: link_params(params),
      sidebars: opts[:sidebars],
      batch_actions: opts[:batch_actions],
      search: is_map(q) and q != %{},
      mod: opts[:mod],
      page_title: opts[:plural_name]
    ]
    |> global_assigns(opts)
    |> additional_assigns(opts)
  end

  # Filters are `:field` or `{:field, opts}` with keyword or map opts; normalise to `{field, map}`.
  defp normalize_filter({field, opts}) when is_list(opts), do: {field, Map.new(opts)}
  defp normalize_filter({field, opts}) when is_map(opts), do: {field, opts}
  defp normalize_filter(field) when is_atom(field), do: {field, %{}}

  defp parse_sort(sort) when is_binary(sort) do
    case String.split(sort, ~r/[+ ]/, parts: 2, trim: true) do
      [field, dir] -> {field, dir}
      [field] -> {field, "asc"}
      _ -> nil
    end
  end

  defp parse_sort(_), do: nil

  @doc "The request params worth carrying across index links: `scope`, `q`, `s` and `per_page`."
  def link_params(params) do
    params
    |> Map.take(["scope", "q", "s", "per_page"])
    |> Enum.reject(fn {_k, v} -> v in [nil, "", %{}, []] end)
    |> Map.new()
  end

  defp global_assigns(assigns, opts) do
    otp_app = Keyword.get(opts, :otp_app, :alkemist)
    conn = opts[:conn]

    global_opts = [
      member_actions: member_actions(opts),
      collection_actions: collection_actions(opts),
      singular_name: opts[:singular_name],
      plural_name: opts[:plural_name],
      alkemist_app: otp_app,
      otp_app: otp_app,
      theme: opts[:theme],
      route_params: Keyword.get(opts, :route_params),
      paths: conn && opts[:controller] && Alkemist.Paths.new(conn, opts[:controller], opts[:route_params]),
      current_path: conn && conn.request_path
    ]

    assigns
    |> Keyword.merge(global_opts)
    |> Keyword.put_new(:page_title, opts[:plural_name])
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
  Builds the filtered, scoped and sorted query for a CSV export without running it.
  Returns `%{query:, columns:, preload:, repo:}`.
  """
  def csv_query(params, resource, opts \\ []) do
    opts = default_csv_opts(opts, resource)
    query = opts[:query]

    scopes =
      Enum.map(opts[:scopes], fn scope ->
        map_scope(scope, query, params, Keyword.put(opts, :scope_counts, false))
      end)

    query = scope(query, scopes)
    columns = Enum.map(opts[:columns], fn col -> map_column(col, resource) end)
    query = opts[:search_provider].run(query, params, provider_opts(opts, resource))

    %{query: query, columns: columns, preload: opts[:preload], repo: opts[:repo]}
  end

  @doc """
  Loads every entry of a CSV export into memory. Prefer `csv_query/3` with
  `Alkemist.Export.CSV.send_stream/4`.
  """
  @deprecated "Use csv_query/3"
  def csv_assigns(params, resource, opts \\ []) do
    %{query: query, columns: columns, preload: preload, repo: repo} =
      csv_query(params, resource, opts)

    [entries: query |> do_preload(preload) |> repo.all(), columns: columns]
  end

  # Options every search/pagination provider call receives.
  defp provider_opts(opts, resource) do
    [
      schema: resource,
      repo: opts[:repo],
      otp_app: Keyword.get(opts, :otp_app, :alkemist),
      timezone: Alkemist.Config.get(:timezone, Keyword.get(opts, :otp_app, :alkemist))
    ]
  end

  defp show_title(fun, resource, _singular) when is_function(fun, 1), do: to_string(fun.(resource))
  defp show_title(title, _resource, _singular) when is_binary(title), do: title
  defp show_title(_none, resource, singular), do: "#{singular} #{Alkemist.Components.Table.pk(resource)}"

  defp put_default_sort(params, nil), do: params
  defp put_default_sort(params, sort_by), do: Map.put_new(params, "s", sort_by)

  @doc """
  Creates the view assigns for the new and edit actions: `form` (a `Phoenix.HTML.Form`
  built from the changeset), `form_fields` (groups of `{key, opts}`), `form_action` and
  `form_method` (create or update, derived from the changeset data), `form_partial`.
  """
  def form_assigns(resource, opts \\ []) do
    opts = default_form_opts(opts, resource)
    changeset = generate_changeset(resource, opts)
    record = changeset.data
    new? = match?(%{__meta__: %{state: :built}}, record) or is_nil(Alkemist.Components.Table.pk(record))
    paths = opts[:conn] && opts[:controller] && Alkemist.Paths.new(opts[:conn], opts[:controller], opts[:route_params])

    fields =
      if opts[:fields] do
        map_form_fields(opts[:fields], [], resource, opts)
      else
        []
      end

    [
      struct: opts[:struct] || Utils.get_struct(resource),
      changeset: changeset,
      form: Phoenix.Component.to_form(changeset, as: opts[:struct] || Utils.get_struct(resource)),
      resource: record,
      mod: opts[:mod],
      form_partial: opts[:form_partial],
      form_fields: fields,
      form_action:
        paths && if(new?, do: Alkemist.Paths.for(paths, :create), else: Alkemist.Paths.for(paths, :update, record)),
      form_method: if(new?, do: "post", else: "put"),
      page_title:
        if(new?,
          do: "New #{opts[:singular_name]}",
          else: "Edit #{opts[:singular_name]} #{Alkemist.Components.Table.pk(record)}"
        )
    ]
    |> Keyword.put(:action, nil)
    |> global_assigns(opts)
    |> additional_assigns(opts)
    |> then(fn assigns -> Keyword.put(assigns, :action, assigns[:form_action]) end)
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
      |> do_preload_resource(opts[:preload], opts[:repo])

    [
      struct: Utils.get_struct(struct),
      resource: resource,
      mod: resource.__struct__,
      rows: rows,
      panels: Keyword.get(opts, :show_panels, []),
      sidebars: Keyword.get(opts, :sidebars, []),
      active_tab: opts[:conn] && opts[:conn].params["tab"],
      page_title: show_title(opts[:title], resource, opts[:singular_name])
    ]
    |> global_assigns(opts)
    |> additional_assigns(opts)
  end

  defp global_opts(opts, resource) do
    opts
    |> Keyword.put_new(:repo, Alkemist.Config.repo(Keyword.get(opts, :otp_app, :alkemist)))
    |> Keyword.put_new(:collection_actions, @default_collection_actions)
    |> Keyword.put_new(:member_actions, @default_member_actions)
    |> Keyword.put_new(:singular_name, Utils.singular_name(resource))
    |> Keyword.put_new(:plural_name, Utils.plural_name(resource))
    |> Keyword.put_new(:alkemist_app, Keyword.get(opts, :otp_app, :alkemist))
    |> Keyword.put_new(:route_params, [])
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
    |> Keyword.put_new_lazy(:search_provider, fn ->
      Alkemist.Config.search_provider(otp_app(opts))
    end)
    |> Keyword.put_new_lazy(:pagination_provider, fn ->
      Alkemist.Config.pagination_provider(otp_app(opts))
    end)
    |> Keyword.put_new(:mod, resource)
    |> Keyword.put_new(:batch_actions, [])
    |> Keyword.put_new(:sidebars, [])
    |> Keyword.put_new_lazy(:sort_by, fn -> Alkemist.Schema.default_sort(resource) end)
    |> Keyword.put_new_lazy(:scope_counts, fn ->
      Alkemist.Config.pagination(otp_app(opts))[:scope_counts]
    end)
  end

  defp otp_app(opts), do: Keyword.get(opts, :otp_app, :alkemist)

  defp default_csv_opts(opts, resource) do
    opts = global_opts(opts, resource)

    opts
    |> Keyword.put_new(:query, resource)
    |> Keyword.put_new(:columns, get_default_columns(resource))
    |> Keyword.put_new(:scopes, [])
    |> Keyword.put_new_lazy(:search_provider, fn ->
      Alkemist.Config.search_provider(otp_app(opts))
    end)
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

    opts
    |> Keyword.put_new_lazy(:changeset, fn -> resource.changeset(struct(resource), %{}) end)
    |> Keyword.put_new(:resource, resource)
    |> Keyword.put_new(:mod, resource)
    |> Keyword.put_new_lazy(:fields, fn -> get_default_form_fields(resource) end)
    |> Keyword.update(:form_partial, nil, &normalize_form_partial/1)
  end

  # `form_partial` is a function component: `{Module, :fun}` or a capture. The 2.x
  # `{View, "template.html"}` tuples cannot be rendered any more.
  defp normalize_form_partial(nil), do: nil
  defp normalize_form_partial({mod, fun}) when is_atom(mod) and is_atom(fun), do: {mod, fun}
  defp normalize_form_partial(fun) when is_function(fun, 1), do: fun

  defp normalize_form_partial(other) do
    raise ArgumentError,
          "form_partial must be a function component ({Module, :fun} or &Module.fun/1), got #{inspect(other)}. " <>
            "Alkemist 3.0 renders forms with Phoenix.Component; see guides/upgrading_to_3_0.md."
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

  defp do_preload_resource(resource, nil, _repo), do: resource
  defp do_preload_resource(resource, preloads, repo), do: repo.preload(resource, preloads)

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

    opts = unless Map.has_key?(opts, :field), do: Map.put(opts, :field, :id), else: opts
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

  defp check_sortable(opts, field) do
    case Map.get(opts, :type) do
      a when a in @sortable_types ->
        unless field == nil do
          Map.put(opts, :sortable, true)
        else
          opts
        end

      _ ->
        opts
    end
  end

  # Creates an Enum of field and callback
  defp map_column({field, callback, opts}, resource) when is_atom(field) do
    opts =
      Map.put(opts, :type, get_field_type(field, resource))
      |> check_sortable(field)
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
      val when val in [:boolean, :integer, :date, :float] ->
        val

      val when val in [:naive_datetime, :naive_datetime_usec, :utc_datetime, :utc_datetime_usec] ->
        :datetime

      :decimal ->
        :number

      {:embed, _} ->
        :embed

      :id ->
        if field == :id do
          :integer
        else
          :select
        end

      _ ->
        :string
    end
  end

  # normalizes the scopes and retrieves the scope counts
  defp map_scope({scope, opts, callback}, query, params, search_opts) do
    query = callback.(query)

    count =
      if search_opts[:scope_counts] == false do
        nil
      else
        search_opts[:search_provider]
        |> apply(:filter, [
          query,
          params,
          provider_opts(search_opts, search_opts[:mod] || search_opts[:query])
        ])
        |> Alkemist.Query.count(search_opts[:repo])
      end

    current = Map.get(params, "scope")

    opts =
      opts
      |> Keyword.put_new(:label, Utils.to_label(scope))
      |> Keyword.put(:count, count)

    opts =
      cond do
        current != nil && "#{scope}" == current -> Keyword.put(opts, :active, true)
        current == nil && opts[:default] == true -> Keyword.put(opts, :active, true)
        true -> Keyword.put(opts, :active, false)
      end

    {scope, opts, callback}
  end

  defp map_scope({scope, opts}, query, params, search_opts),
    do: map_scope({scope, opts, fn q -> q end}, query, params, search_opts)

  defp map_scope(scope, query, params, search_opts),
    do: map_scope({scope, []}, query, params, search_opts)

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
    opts =
      case Keyword.get(@default_action_opts, action) do
        nil -> opts
        default -> Keyword.merge(default, opts)
      end

    opts =
      if singular do
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
