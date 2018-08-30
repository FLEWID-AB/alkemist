defmodule AlkemistView do
  use Alkemist, :view
  # use Rummage.Phoenix.View, helpers: Alkemist.Config.router_helpers()
  import Alkemist.SearchView
  import Alkemist.FormView

  @doc """
  Returns the current user if it is provided in the authorization provider
  """
  def current_user(conn) do
    Alkemist.Config.authorization_provider().current_user(conn)
  end

  @doc """
  Boolean indicator if a column is sortable
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

  def export_action(conn, struct) do
    query_params =
      %{}
      |> add_scope_param(conn.params)
      |> add_search_param(conn.params)

    params = [conn, :export, query_params]
    action(struct, params, label: "Export", link_opts: [class: "nav-link"])
  end

  defp add_scope_param(query_params, params) do
    case Map.get(params, "scope") do
      nil -> query_params
      scope -> Map.put(query_params, "scope", scope)
    end
  end

  defp add_search_param(query_params, params) do
    case Map.get(params, "rummage") do
      nil ->
        query_params

      rummage ->
        Map.put(query_params, "rummage", %{"search" => Map.get(rummage, "search", %{})})
    end
  end

  def action_path(struct, params) do
    path_function_name = String.to_atom("#{struct}_path")
    apply(Alkemist.Config.router_helpers(), path_function_name, params)
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
      %{scope: scope}
      |> add_search_param(conn.params)

    content_tag(:li, class: "nav-item") do
      link(label, to: action_path(struct, [conn, :index, query_params]), class: class)
    end
  end

  def string_value(callback, row) do
    val = callback.(row)
    field_string_value(val)
  end

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
