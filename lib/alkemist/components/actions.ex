defmodule Alkemist.Components.Actions do
  @moduledoc """
  Links and buttons around a resource: member actions (as header buttons or menu items),
  collection actions, the export link, scope tabs and batch actions. Every link is
  authorization-gated through the configured `Alkemist.Authorization` provider.
  """
  use Phoenix.Component
  use Gettext, backend: Alkemist.Gettext
  import Alkemist.Components.Icons
  import Alkemist.Components.Core, only: [button: 1, dropdown: 1, tabs: 1]

  alias Alkemist.{Authorization, Config, Paths}

  @doc """
  One action link. `action` is `{name, opts}` from `Alkemist.Assign.format_action/2`.
  `variant` is `"button"` (page header), `"menu"` (dropdown item) or `"icon"`.
  """
  attr :action, :any, required: true
  attr :resource, :any, required: true, doc: "record for member actions, schema module for collection actions"
  attr :paths, Paths, required: true
  attr :conn, :any, required: true
  attr :alkemist_app, :atom, default: :alkemist
  attr :variant, :string, default: "menu", values: ~w(icon button menu)
  attr :button_variant, :string, default: nil, doc: "overrides the button style for the `button` variant"

  def action_link(%{action: {name, opts}} = assigns) do
    provider = Config.authorization_provider(assigns.alkemist_app)
    link_opts = Keyword.get(opts, :link_opts, [])
    record = if is_atom(assigns.resource), do: nil, else: assigns.resource
    danger? = opts[:danger] == true or name == :delete

    assigns =
      assign(assigns,
        name: name,
        label: to_string(opts[:label] || Alkemist.Naming.humanize(name)),
        icon: normalize_icon(opts[:icon]),
        danger?: danger?,
        authorized?: Authorization.authorized?(provider, assigns.resource, assigns.conn, name),
        href: Keyword.get(link_opts, :to) || Paths.for(assigns.paths, name, record),
        method: link_opts |> Keyword.get(:method) |> method(),
        confirm: get_in(link_opts, [:data, :confirm]),
        button_variant:
          assigns.button_variant ||
            cond do
              name == :new -> "primary"
              danger? -> "danger"
              true -> "secondary"
            end
      )

    ~H"""
    <.link
      :if={@authorized? && @variant == "menu"}
      href={@href}
      method={@method || "get"}
      data-confirm={@confirm}
      class={["ak-dropdown__item", @danger? && "ak-dropdown__item--danger"]}
      role="menuitem"
    >
      <.icon :if={@icon} name={@icon} />{@label}
    </.link>
    <.button
      :if={@authorized? && @variant == "button"}
      href={@href}
      method={@method || "get"}
      data-confirm={@confirm}
      variant={@button_variant}
      icon={@icon}
    >
      {@label}
    </.button>
    <.button
      :if={@authorized? && @variant == "icon"}
      href={@href}
      method={@method || "get"}
      data-confirm={@confirm}
      variant="ghost"
      size="sm"
      icon={@icon || "hero-ellipsis-horizontal"}
      label={@label}
    />
    """
  end

  @doc "Collection actions (`new` and custom ones) as header buttons."
  attr :actions, :list, required: true
  attr :resource, :atom, required: true
  attr :paths, Paths, required: true
  attr :conn, :any, required: true
  attr :alkemist_app, :atom, default: :alkemist

  def collection_actions(assigns) do
    ~H"""
    <.action_link
      :for={action <- @actions}
      action={action}
      resource={@resource}
      paths={@paths}
      conn={@conn}
      alkemist_app={@alkemist_app}
      variant="button"
    />
    """
  end

  @doc "The export link, carrying the current scope, filters and sort."
  attr :paths, Paths, required: true
  attr :link_params, :map, default: %{}
  attr :resource, :atom, required: true
  attr :conn, :any, required: true
  attr :alkemist_app, :atom, default: :alkemist

  def export_link(assigns) do
    provider = Config.authorization_provider(assigns.alkemist_app)

    assigns =
      assign(assigns, :authorized?, Authorization.authorized?(provider, assigns.resource, assigns.conn, :export))

    ~H"""
    <.button
      :if={@authorized?}
      href={Paths.for(@paths, :export, query: @link_params)}
      variant="secondary"
      icon="hero-arrow-down-tray"
    >
      {gettext("Export CSV")}
    </.button>
    """
  end

  @doc "Scopes as underline tabs with counts."
  attr :scopes, :list, required: true, doc: "`{scope, opts, callback}` tuples from `Alkemist.Assign`"
  attr :paths, Paths, required: true
  attr :link_params, :map, default: %{}

  def scopes(assigns) do
    items =
      for {scope, opts, _cb} <- assigns.scopes do
        query = assigns.link_params |> Map.put("scope", to_string(scope)) |> Map.delete("page")

        %{
          label: opts[:label],
          count: opts[:count],
          current?: opts[:active] == true,
          href: Paths.for(assigns.paths, :index, query: query)
        }
      end

    assigns = assign(assigns, :items, items)

    ~H"""
    <.tabs items={@items} label={gettext("Scopes")} />
    """
  end

  @doc "Batch actions: a form the row checkboxes attach to and a menu of submit buttons."
  attr :actions, :list, required: true
  attr :paths, Paths, required: true

  def batch_actions(assigns) do
    ~H"""
    <form id="batch-action-form" method="post" hidden>
      <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
    </form>
    <.dropdown id="batch-actions" label={gettext("Batch actions")} variant="secondary">
      <button
        :for={{name, opts} <- Enum.map(@actions, &normalize_action/1)}
        type="submit"
        form="batch-action-form"
        formaction={Paths.for(@paths, name)}
        data-confirm={opts[:confirm]}
        class="ak-dropdown__item"
        role="menuitem"
        disabled
      >
        {opts[:label] || Alkemist.Naming.humanize(name)}
      </button>
    </.dropdown>
    """
  end

  defp normalize_action({name, opts}), do: {name, Map.new(opts)}
  defp normalize_action(name) when is_atom(name), do: {name, %{}}

  defp method(nil), do: nil
  defp method(m), do: to_string(m)

  defp normalize_icon(nil), do: nil
  defp normalize_icon(false), do: nil
  defp normalize_icon("hero-" <> _ = icon), do: icon

  defp normalize_icon(other) do
    raise ArgumentError, "action icons must be Heroicons names such as \"hero-pencil-square\", got #{inspect(other)}"
  end
end
