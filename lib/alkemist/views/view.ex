defmodule AlkemistView do
  use Alkemist, :view
  import Alkemist.SearchView
  import Alkemist.FormView
  import Alkemist.PaginationView

  @doc """
  Boolean indicator if a column is sortable

  ## Examples:

    iex> AlkemistView.is_sortable?({:col, nil, [sortable: true]})
    true

    iex> AlkemistView.is_sortable?({:col, nil, []})
    false
  """
  def is_sortable?({_col, _cb, opts}) do
    Keyword.get(opts, :sortable, false) == true
  end

  @doc """
  Renders the member actions for a table row
  """
  def member_actions(actions, application \\ :alkemist) do
    {mod, fun} = Alkemist.Config.member_actions_decorator(application)
    apply(mod, fun, [actions])
  end
  def member_actions(conn, actions, resource, route_params, application \\ :alkemist) do
    {mod, fun} = Alkemist.Config.member_actions_decorator(application)
    apply(mod, fun, [conn, actions, resource, route_params, application])
  end

  @doc """
  Decorator for the actions column - will render default links
  """
  def member_actions_decorator(actions) do
    if Enum.any?(actions) do
      content_tag(:th, class: "member-actions") do
        "Actions"
      end
    end
  end
  def member_actions_decorator(conn, actions, resource, route_params, application \\ :alkemist) do
    if Enum.any?(actions) do
      content_tag(:td, class: "member-actions") do
        Enum.map(actions, fn action -> member_action(conn, action, resource, route_params, application) end)
      end
    end
  end

  @doc """
  Creates an action link to a member action
  """
  def member_action(conn, action, resource, route_params, application \\ :alkemist) do
    {action, opts} = action
    label =
      case Keyword.get(opts, :icon) do
        nil ->
          opts[:label]

        icon_class ->
          """
          <i class="#{icon_class}"></i>
          """
      end

    link_opts = Keyword.get(opts, :link_opts, [])
    link_opts =
      link_opts
      |> Keyword.put(:alkemist_app, application)
      |> Keyword.put(:route_params, route_params)
    action_link(label, conn, action, resource, link_opts)
  end

  @doc """
  Creates a collection action link above the index table
  """
  def collection_action(conn, action, resource, route_params, application \\ :alkemist) do
    {action, opts} = action

    label =
      case Keyword.get(opts, :icon) do
        nil ->
          opts[:label]

        icon_class ->
          """
          <i class="#{icon_class}"></i>
          """
      end

    link_opts =
      Keyword.get(opts, :link_opts, [])
      |> Keyword.put_new(:class, "nav-link")
      |> Keyword.put(:alkemist_app, application)
      |> Keyword.put(:route_params, route_params)

    action_link(label, conn, action, resource, link_opts)
  end

  @doc """
  Create a link to the export action
  """
  def export_action(conn, struct, _assigns \\ [], application \\ :alkemist) do
    query_params = get_default_link_params(conn)


    params = [conn, :export, query_params]
    action(struct, params, label: "Export", link_opts: [class: "nav-link"], alkemist_app: application)
  end

  @doc """
  Returns the path for a controller action
  """
  def action_path(struct, params, application \\ :alkemist) do
    path_function_name = Alkemist.Utils.default_struct_helper(struct)
    apply(Alkemist.Config.router_helpers(application), path_function_name, params)
  end


  @doc """
  Renders a batch action item
  """
  def batch_action_item(conn, struct, batch_action, application \\ :alkemist) do
    {action, opts} =
      if is_atom(batch_action) do
        {batch_action, []}
      else
        batch_action
      end

    label = Keyword.get(opts, :label, Phoenix.Naming.humanize(action))

    opts =
      opts
      |> Keyword.put(:to, "#")
      |> Keyword.put(:class, "dropdown-item batch-action-item")
      |> Keyword.delete(:label)
      |> Keyword.put(:"data-action", action_path(struct, [conn, action], application))

    link(label, opts)
  end

  @doc """
  Creates a scope link
  """
  def scope_link(conn, scope, struct, application \\ :alkemist) do
    {scope, opts, _} = scope

    label =
      """
      <span class="label">#{opts[:label]}</span> <span class="count">#{opts[:count]}</span>
      """
      |> raw()

    class =
      if opts[:active] == true do
        "nav-link active"
      else
        "nav-link"
      end

    query_params =
      get_default_link_params(conn)
      |> Map.put(:scope, scope)

    content_tag(:li, class: "nav-item") do
      link(label, to: action_path(struct, [conn, :index, query_params], application), class: class)
    end
  end

  @doc """
  Creates the header cell for the index table
  Accepts the conn, struct and actual column created by `Alkemist.Assign.map_column`
  """
  def header_cell(conn, struct, opts, application \\ :alkemist)
  def header_cell(conn, struct, {field, _cb, %{sortable: true} = opts}, application) do
    query_params = get_default_link_params(conn)
    direction = if Map.get(query_params, "s") == "#{field}+asc" do
          "desc"
        else
          "asc"
        end
    icon = cond do
      Map.get(query_params, "s") == "#{field}+asc" -> "fas fa-sort-up"
      Map.get(query_params, "s") == "#{field}+desc" -> "fas fa-sort-down"
      true -> "fas fa-sort"
    end
    query_params = Map.put(query_params, "s", "#{field}+#{direction}")
    class = ["index-header", Map.get(opts, :type)]

    label = Map.get(opts, :label) <> " <i class=\"#{icon}\"></i>"
    content_tag(:th, class: Enum.join(class, " ")) do
      params = [conn, :index] ++ route_params(opts[:route_params]) ++ [query_params]
      link(raw(label), to: action_path(struct, params, application))
    end
  end
  def header_cell(_conn, _struct, {_field, _callback, opts}, _application) do
    label = Map.get(opts, :label)
    class = ["index-header", Slugger.slugify_downcase(label), Map.get(opts, :type)]
    content_tag(:th, class: Enum.join(class, " ")) do
      label
    end
  end

  defp route_params(nil), do: []
  defp route_params(params) when is_list(params), do: params
  defp route_params(params), do: [params]

  def string_value(callback, row) do
    val = callback.(row)
    {module, func} = Alkemist.Config.field_value_decorator()
    apply(module, func, [val])
  end

  def field_string_value({:safe, _} = val), do: val
  def field_string_value(val) when is_bitstring(val), do: raw(val)

  def field_string_value(val) when is_boolean(val) do
    icon =
      if val do
        "fa-check"
      else
        "fa-times"
      end

    """
    <i class="fas fa-fw #{icon}"></i>
    """
    |> raw()
  end

  def field_string_value(%NaiveDateTime{} = nd) do
    "#{nd.day}.#{nd.month}.#{nd.year} - #{nd.hour}:#{nd.minute}:#{nd.second}"
  end

  def field_string_value(%Date{} = d) do
    String.pad_leading("#{d.day}", 2, "0") <> "." <>
    String.pad_leading("#{d.month}", 2, "0") <> ".#{d.year}"
  end

  def field_string_value(val) when is_map(val), do: "#Object"
  def field_string_value(val), do: "#{val}"

  defp action(struct, params, opts) do
    application = Keyword.get(opts, :alkemist_app, :alkemist)
    path = action_path(struct, params, application)

    label =
      case Keyword.get(opts, :icon) do
        nil ->
          opts[:label]

        icon_class ->
          """
          <i class="#{icon_class}"></i>
          """
          |> raw()
      end

    link_opts =
      Keyword.get(opts, :link_opts, [])
      |> Keyword.put_new(:to, path)
      |> Keyword.put_new(:title, opts[:label])

    link(label, link_opts)
  end
end
