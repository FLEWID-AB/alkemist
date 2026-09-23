defmodule Alkemist.Components.Layout do
  @moduledoc """
  Structural pieces of the admin shell: the grid, the brand, the account footer and the
  two-column content layout. The default arrangement lives in the default theme's
  `app/1`; hosts recompose these in their own theme module.
  """
  use Phoenix.Component
  use Gettext, backend: Alkemist.Gettext
  import Alkemist.Components.Icons

  @doc "The page grid: the sidebar on the left, the main column on the right."
  attr :class, :any, default: nil
  slot :sidebar, required: true
  slot :inner_block, required: true

  def shell(assigns) do
    ~H"""
    <div class={["ak-shell", @class]}>
      <a href="#ak-main" class="ak-skip">{gettext("Skip to content")}</a>
      <nav class="ak-sidebar" aria-label={gettext("Main navigation")}>{render_slot(@sidebar)}</nav>
      <main id="ak-main" class="ak-main" tabindex="-1">{render_slot(@inner_block)}</main>
    </div>
    """
  end

  @doc "Brand at the top of the sidebar: the logo image when configured, otherwise the title."
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :logo, :any, default: false, doc: "a path served by the host app, or `false`"
  attr :href, :string, default: "/"

  def brand_link(assigns) do
    ~H"""
    <a href={@href} class="ak-brand">
      <img :if={@logo} src={@logo} alt={@title} />
      <span :if={!@logo} class="ak-brand__name">{@title}</span>
      <span :if={@subtitle} class="ak-brand__sub">{@subtitle}</span>
    </a>
    """
  end

  @doc "The account footer of the sidebar: the current user, an environment label, sign out."
  attr :name, :string, default: nil
  attr :environment, :string, default: nil
  attr :sign_out, :any, default: nil, doc: "`[path: \"/logout\", method: :delete]` or nil"

  def account_footer(assigns) do
    ~H"""
    <div :if={@name || @environment} class="ak-account">
      <div class="ak-account__avatar"><.icon name="hero-user" class="size-3.5" /></div>
      <div class="ak-account__text">
        <span :if={@name} class="ak-account__name">{@name}</span>
        <span :if={@environment} class="ak-account__env">{@environment}</span>
      </div>
      <.link
        :if={@sign_out}
        href={@sign_out[:path]}
        method={to_string(@sign_out[:method] || "get")}
        class="ak-btn ak-btn--ghost ak-btn--icon ak-btn--sm"
        aria-label={gettext("Sign out")}
      >
        <.icon name="hero-arrow-right-start-on-rectangle" />
      </.link>
    </div>
    """
  end

  @doc "Two columns: the main content and a fixed-width aside of cards on the right."
  slot :inner_block, required: true
  slot :aside

  def columns(assigns) do
    ~H"""
    <div class="ak-columns">
      <div class="ak-columns__main">{render_slot(@inner_block)}</div>
      <aside :if={@aside != []} class="ak-columns__aside" aria-label={gettext("Details")}>{render_slot(@aside)}</aside>
    </div>
    """
  end

  @doc "A panel card: `{label, content: html}` or `{label, component: {mod, fun}}`."
  attr :title, :string, required: true
  slot :inner_block, required: true

  def aside_panel(assigns) do
    ~H"""
    <section class="ak-card">
      <header class="ak-card__header">
        <h2 class="ak-card__title">{@title}</h2>
      </header>
      <div class="ak-card__body">{render_slot(@inner_block)}</div>
    </section>
    """
  end
end
