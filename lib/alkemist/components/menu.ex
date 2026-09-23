defmodule Alkemist.Components.Menu do
  @moduledoc """
  Sidebar navigation built from `Alkemist.Menu.items/1`. Items with a `parent` are
  grouped under an uppercase, collapsible group label; items may carry an `icon:`
  (a `hero-*` name). Entries the current user may not `:index` are hidden.
  """
  use Phoenix.Component
  import Alkemist.Components.Icons

  alias Alkemist.{Authorization, Config, Routes}

  @doc "Renders the menu tree."
  attr :items, :list, required: true, doc: "from `Alkemist.Menu.items/1`"
  attr :conn, :any, required: true
  attr :current_path, :string, default: nil
  attr :alkemist_app, :atom, default: :alkemist

  def sidebar_nav(assigns) do
    assigns = assign(assigns, :items, Enum.flat_map(assigns.items, &visible(&1, assigns)))

    ~H"""
    <ul class="ak-nav">
      <li :for={item <- @items}>
        <details :if={item.type == :branch} class="ak-nav__group" open>
          <summary>{item.label}<.icon name="hero-chevron-down" /></summary>
          <ul class="ak-nav__children">
            <li :for={child <- item.children}><.menu_link item={child} /></li>
          </ul>
        </details>
        <.menu_link :if={item.type == :leaf} item={item} />
      </li>
    </ul>
    """
  end

  attr :item, :map, required: true

  defp menu_link(assigns) do
    ~H"""
    <a href={@item.to} class="ak-nav__link" aria-current={@item.current && "page"}>
      <.icon :if={@item[:icon]} name={@item.icon} /><span>{@item.label}</span>
    </a>
    """
  end

  # Resolves paths and authorization; drops leaves the user may not see and empty branches.
  defp visible(%{type: :branch, children: children} = branch, assigns) do
    case Enum.flat_map(children, &visible(&1, assigns)) do
      [] -> []
      kids -> [%{branch | children: kids}]
    end
  end

  defp visible(%{type: :leaf} = item, %{conn: conn, current_path: current, alkemist_app: app}) do
    provider = Config.authorization_provider(app)

    if is_binary(item.resource) or Authorization.authorized?(provider, item.resource, conn, :index) do
      to = item[:to] || Routes.path(conn, item.controller, :index)
      [Map.merge(item, %{to: to, current: current?(to, current)})]
    else
      []
    end
  end

  defp current?(_to, nil), do: false
  defp current?(to, current), do: current == to or String.starts_with?(current, to <> "/")
end
