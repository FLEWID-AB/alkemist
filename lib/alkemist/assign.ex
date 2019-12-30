defmodule Alkemist.Assign do
  @moduledoc """
  Provides helper functions for generic CRUD assigns
  """
  import Ecto.Query
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
    |> Keyword.merge(Alkemist.Assign.Global.assigns(opts))
    |> Keyword.merge(Keyword.get(opts, :assigns, []))
  end

  @doc """
  Creates the assigns for the show view
  Params:
    * resource - a single entry from the DB
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

  defp default_form_opts(opts, resource) do
    opts = Alkemist.Assign.Global.opts(opts, resource)

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
      |> Keyword.put_new(:fields, Utils.editable_fields(resource))
      |> Keyword.put(:form_partial, {AlkemistView, "form.html"})
    end
  end

  # Add preloads to the query if any are given
  defp do_preload(query, preloads) do
    if preloads == nil do
      query
    else
      from(r in query, preload: ^preloads)
    end
  end

  defp do_preload_resource(resource, preloads, application) do
    if preloads == nil do
      resource
    else
      resource |> Alkemist.Config.repo(application).preload(preloads)
    end
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
      |> Map.put_new(:type, Utils.get_field_type(field, resource))

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
end
