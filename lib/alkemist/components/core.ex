defmodule Alkemist.Components.Core do
  @moduledoc """
  Building blocks shared by every Alkemist page: buttons, cards, badges, tabs, the page
  header band, toasts, dropdowns and empty states. Styled by the `.ak-*` classes in
  `assets/css/alkemist-components.css`; colours come from the `--ak-*` tokens.
  """
  use Phoenix.Component
  use Gettext, backend: Alkemist.Gettext
  import Alkemist.Components.Icons

  @doc """
  A button or button-styled link. One job each: `primary` for the main action of a page,
  `secondary` for other actions, `ghost` for tertiary ones, `danger` for destructive ones.
  """
  attr :variant, :string, default: "primary", values: ~w(primary secondary ghost danger)
  attr :size, :string, default: "md", values: ~w(md sm xs)
  attr :href, :string, default: nil, doc: "renders an `<a>` instead of a `<button>`"
  attr :method, :string, default: nil, doc: "with `href`: a non-GET method, via phoenix_html's data-method"
  attr :icon, :string, default: nil
  attr :label, :string, default: nil, doc: "accessible label for icon-only buttons"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(type disabled form formaction formmethod data-confirm name value)
  slot :inner_block

  def button(assigns) do
    icon_only? = assigns.inner_block == [] and not is_nil(assigns.icon)

    assigns =
      assign(assigns,
        icon_only?: icon_only?,
        classes: [
          "ak-btn",
          "ak-btn--#{assigns.variant}",
          assigns.size != "md" && "ak-btn--#{assigns.size}",
          icon_only? && "ak-btn--icon",
          assigns.class
        ]
      )

    ~H"""
    <.link :if={@href} href={@href} method={@method || "get"} class={@classes} aria-label={@icon_only? && @label} {@rest}>
      <.icon :if={@icon} name={@icon} />{render_slot(@inner_block)}
    </.link>
    <button
      :if={!@href}
      type={@rest[:type] || "button"}
      class={@classes}
      aria-label={@icon_only? && @label}
      {Map.delete(@rest, :type)}
    >
      <.icon :if={@icon} name={@icon} />{render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  A bordered surface with an optional header. The body is padded unless `flush` is set,
  which suits tables and detail lists that bring their own row padding.
  """
  attr :title, :string, default: nil
  attr :flush, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :actions
  slot :footer
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <section class={["ak-card", @class]} {@rest}>
      <header :if={@title || @actions != []} class="ak-card__header">
        <h2 :if={@title} class="ak-card__title">{@title}</h2>
        <div :if={@actions != []} class="ak-page-header__actions">{render_slot(@actions)}</div>
      </header>
      <div :if={!@flush} class="ak-card__body">{render_slot(@inner_block)}</div>
      <%= if @flush do %>
        {render_slot(@inner_block)}
      <% end %>
      <footer :if={@footer != []} class="ak-card__footer">{render_slot(@footer)}</footer>
    </section>
    """
  end

  @doc "A small status label. `dot` adds a coloured status dot."
  attr :variant, :string, default: "neutral", values: ~w(neutral ok info warn danger mono)
  attr :dot, :boolean, default: false
  attr :icon, :string, default: nil
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={["ak-badge", @variant != "neutral" && "ak-badge--#{@variant}", @class]}>
      <span :if={@dot} class="ak-badge__dot" aria-hidden="true"></span><.icon :if={@icon} name={@icon} />{render_slot(
        @inner_block
      )}
    </span>
    """
  end

  @doc "A mono count chip, as used in tabs."
  attr :value, :any, required: true

  def count(assigns) do
    ~H"""
    <span class="ak-count">{format_count(@value)}</span>
    """
  end

  @doc false
  def format_count(n) when is_integer(n) do
    n
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1 ")
    |> String.reverse()
  end

  def format_count(other), do: to_string(other)

  @doc "Underline tabs. Each item is `%{label:, href:, current?:, count:}`; links, not buttons."
  attr :items, :list, required: true
  attr :label, :string, required: true, doc: "accessible name of the tab list"

  def tabs(assigns) do
    ~H"""
    <nav class="ak-tabs" aria-label={@label}>
      <a :for={item <- @items} href={item.href} class="ak-tab" aria-current={item[:current?] && "page"}>
        {item.label}<.count :if={item[:count] != nil} value={item.count} />
      </a>
    </nav>
    """
  end

  @doc """
  The white band at the top of every page: an optional back link, the title with an
  optional description and badges, actions on the right and optional tabs underneath.
  """
  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :back_href, :string, default: nil
  attr :back_label, :string, default: nil
  slot :badges
  slot :actions
  slot :tabs
  slot :inner_block

  def page_header(assigns) do
    ~H"""
    <header class={["ak-page-header", @tabs != [] && "ak-page-header--tabs"]}>
      <a :if={@back_href} href={@back_href} class="ak-page-header__back">
        <.icon name="hero-chevron-left" class="size-3" />{@back_label || gettext("Back")}
      </a>
      <div class="ak-page-header__row">
        <div class="ak-page-header__title">
          <div class="flex items-center gap-3 min-w-0">
            <h1>{@title}</h1>
            {render_slot(@badges)}
          </div>
          <p :if={@description}>{@description}</p>
          {render_slot(@inner_block)}
        </div>
        <div :if={@actions != []} class="ak-page-header__actions">{render_slot(@actions)}</div>
      </div>
      {render_slot(@tabs)}
    </header>
    """
  end

  @doc "One flash message rendered as a toast."
  attr :kind, :atom, required: true, values: [:info, :error]
  attr :flash, :map, required: true

  def flash(assigns) do
    assigns = assign(assigns, :message, Phoenix.Flash.get(assigns.flash, assigns.kind))

    ~H"""
    <div
      :if={@message}
      id={"ak-flash-#{@kind}"}
      role={if @kind == :error, do: "alert", else: "status"}
      class={["ak-toast", "ak-toast--#{@kind}"]}
    >
      <.icon name={if @kind == :error, do: "hero-exclamation-triangle", else: "hero-check"} class="ak-toast__icon" />
      <div class="ak-toast__text"><span class="ak-toast__title">{@message}</span></div>
      <button type="button" class="ak-toast__close" aria-label={gettext("Dismiss")} data-dismiss-toast>
        <.icon name="hero-x-mark" />
      </button>
    </div>
    """
  end

  @doc "The info and error flashes as toasts in the bottom right corner."
  attr :flash, :map, required: true

  def flashes(assigns) do
    ~H"""
    <div id="ak-flash-group" class="ak-toasts" aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
    </div>
    """
  end

  @doc """
  A keyboard-native dropdown built on `<details>`. Give it a `label` for a text trigger or
  only an `icon` (plus `label` as accessible name) for an icon trigger such as "more".
  """
  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :icon, :string, default: nil
  attr :icon_only, :boolean, default: false
  attr :variant, :string, default: "secondary", values: ~w(secondary ghost)
  attr :size, :string, default: "md", values: ~w(md sm)
  attr :align, :string, default: "right", values: ~w(left right)
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown(assigns) do
    ~H"""
    <details id={@id} class={["ak-dropdown", @align == "left" && "ak-dropdown--left", @class]} {@rest}>
      <summary
        class={["ak-btn", "ak-btn--#{@variant}", @size == "sm" && "ak-btn--sm", @icon_only && "ak-btn--icon"]}
        aria-haspopup="menu"
        aria-label={@icon_only && @label}
      >
        <.icon :if={@icon} name={@icon} />
        <%= if !@icon_only do %>
          {@label}<.icon name="hero-chevron-down" class="size-3" />
        <% end %>
      </summary>
      <div class="ak-dropdown__menu" role="menu">{render_slot(@inner_block)}</div>
    </details>
    """
  end

  @doc "Placeholder shown when a list has no entries."
  attr :title, :string, default: nil
  attr :message, :string, default: nil
  attr :icon, :string, default: "hero-document-text"
  slot :inner_block

  def empty_state(assigns) do
    ~H"""
    <div class="ak-empty">
      <.icon name={@icon} />
      <span class="ak-empty__title">{@title || gettext("Nothing here yet")}</span>
      <span :if={@message} class="ak-empty__text">{@message}</span>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
