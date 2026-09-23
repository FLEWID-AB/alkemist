defmodule Alkemist.Components.Show do
  @moduledoc "The show page pieces: the details card and content panels."
  use Phoenix.Component
  use Gettext, backend: Alkemist.Gettext

  alias Alkemist.Components.Theme
  alias Alkemist.Paths

  @doc "Label / value rows of the record (same column syntax as the index)."
  attr :rows, :list, required: true
  attr :resource, :any, required: true
  attr :paths, Paths, required: true
  attr :alkemist_app, :atom, default: :alkemist
  attr :theme, :atom, default: nil

  def details(assigns) do
    ~H"""
    <dl class="ak-details">
      <.detail
        :for={row <- @rows}
        row={row}
        resource={@resource}
        paths={@paths}
        alkemist_app={@alkemist_app}
        theme={@theme}
      />
    </dl>
    """
  end

  attr :row, :any, required: true
  attr :resource, :any, required: true
  attr :paths, Paths, required: true
  attr :alkemist_app, :atom, required: true
  attr :theme, :atom, default: nil

  defp detail(%{row: {_field, callback, opts}, resource: resource} = assigns) do
    assoc_record = if opts[:assoc], do: loaded(Map.get(resource, opts.assoc))
    value = if opts[:assoc] && is_nil(assoc_record), do: nil, else: callback.(resource)

    link =
      if opts[:action] && opts[:resource] && assoc_record,
        do: Paths.for_schema(assigns.paths, opts.resource, opts.action, assoc_record)

    assigns = assign(assigns, value: value, opts: opts, link: link)

    ~H"""
    <div class="ak-details__row">
      <dt class="ak-details__label">{@opts[:label]}</dt>
      <dd class="ak-details__value">
        <a :if={@link} href={@link}><Theme.value
          value={@value}
          column={@opts}
          row={@resource}
          alkemist_app={@alkemist_app}
          theme={@theme}
        /></a>
        <Theme.value :if={!@link} value={@value} column={@opts} row={@resource} alkemist_app={@alkemist_app} theme={@theme} />
      </dd>
    </div>
    """
  end

  @doc "A titled card whose content comes from `component:` or `content:`."
  attr :title, :string, required: true
  attr :opts, :any, required: true
  attr :page_assigns, :map, required: true

  def panel(assigns) do
    assigns = assign(assigns, :content, Alkemist.Theme.Default.panel_content(assigns.opts, assigns.page_assigns))

    ~H"""
    <section class="ak-card">
      <header class="ak-card__header">
        <h2 class="ak-card__title">{@title}</h2>
      </header>
      <div class="ak-card__body">{@content}</div>
    </section>
    """
  end

  @doc """
  The tabs of a show page: "Overview" plus one per distinct `tab:` in the panels, linking
  with `?tab=<slug>`.
  """
  @spec tab_items([{String.t(), keyword()}], String.t() | nil, Paths.t(), struct()) :: [map()]
  def tab_items(panels, active, paths, resource) do
    tabs = panels |> Enum.map(fn {_l, o} -> o[:tab] end) |> Enum.reject(&is_nil/1) |> Enum.uniq()

    if tabs == [] do
      []
    else
      overview = %{label: gettext("Overview"), href: Paths.for(paths, :show, resource), current?: active in [nil, ""]}

      rest =
        for tab <- tabs do
          slug = Alkemist.Naming.slugify(tab)

          count =
            panels |> Enum.filter(fn {_l, o} -> o[:tab] == tab end) |> Enum.find_value(fn {_l, o} -> o[:count] end)

          %{
            label: tab,
            count: count,
            current?: active == slug,
            href: Paths.for(paths, :show, resource, query: %{"tab" => slug})
          }
        end

      [overview | rest]
    end
  end

  @doc "The panels that belong on the active tab (untabbed ones on Overview)."
  @spec panels_for_tab([{String.t(), keyword()}], String.t() | nil) :: [{String.t(), keyword()}]
  def panels_for_tab(panels, active) when active in [nil, ""],
    do: Enum.filter(panels, fn {_l, o} -> is_nil(o[:tab]) end)

  def panels_for_tab(panels, active),
    do: Enum.filter(panels, fn {_l, o} -> o[:tab] && Alkemist.Naming.slugify(o[:tab]) == active end)

  defp loaded(%Ecto.Association.NotLoaded{}), do: nil
  defp loaded(value), do: value
end
