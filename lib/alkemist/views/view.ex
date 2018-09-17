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
  Creates an action link to a member action
  """
  def member_action(conn, action, resource) do
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
    action_link(label, conn, action, resource, link_opts)
  end

  @doc """
  Creates a collection action link above the index table
  """
  def collection_action(conn, action, resource) do
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

    action_link(label, conn, action, resource, link_opts)
  end

  @doc """
  Create a link to the export action
  """
  def export_action(conn, struct) do
    query_params = get_default_link_params(conn)

    params = [conn, :export, query_params]
    action(struct, params, label: "Export", link_opts: [class: "nav-link"])
  end

  @doc """
  Returns the path for a controller action
  """
  def action_path(struct, params) do
    path_function_name = String.to_atom("#{struct}_path")
    apply(Alkemist.Config.router_helpers(), path_function_name, params)
  end

  @doc """
  Renders a batch action item
  """
  def batch_action_item(conn, struct, batch_action) do
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
      |> Keyword.put(:"data-action", action_path(struct, [conn, action]))

    link(label, opts)
  end

  @doc """
  Creates a scope link
  """
  def scope_link(conn, scope, struct) do
    {scope, opts, _} = scope

    label =
      """
      #{opts[:label]} <span class="badge badge-secondary">#{opts[:count]}</span>
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
      link(label, to: action_path(struct, [conn, :index, query_params]), class: class)
    end
  end

  def string_value(callback, row) do
    val = callback.(row)
    field_string_value(val)
  end

  defp field_string_value({:safe, _} = val), do: val
  defp field_string_value(val) when is_bitstring(val), do: raw(val)

  defp field_string_value(val) when is_boolean(val) do
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

  defp field_string_value(%NaiveDateTime{} = nd) do
    "#{nd.day}.#{nd.month}.#{nd.year} - #{nd.hour}:#{nd.minute}:#{nd.second}"
  end

  defp field_string_value(val) when is_map(val), do: "#Object"
  defp field_string_value(val), do: "#{val}"

  defp action(struct, params, opts) do
    path = action_path(struct, params)

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
