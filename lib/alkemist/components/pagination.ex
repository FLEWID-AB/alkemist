defmodule Alkemist.Components.Pagination do
  @moduledoc """
  The pagination bar at the foot of the index table: the range shown, page buttons with
  gaps, and a rows-per-page selector.
  """
  use Phoenix.Component
  use Gettext, backend: Alkemist.Gettext
  import Alkemist.Components.Icons
  import Alkemist.Components.Core, only: [format_count: 1]

  alias Alkemist.Paths

  @doc "The pagination bar."
  attr :pagination, :any, required: true, doc: "`%Alkemist.Query.Page{}` or a map with the same keys"
  attr :entries_count, :integer, default: 0
  attr :paths, Paths, required: true
  attr :link_params, :map, default: %{}
  attr :per_page_options, :list, default: [10, 25, 50, 100]

  def pagination(assigns) do
    %{current_page: page, per_page: per_page, total_count: total} = assigns.pagination
    first = if total == 0, do: 0, else: (page - 1) * per_page + 1
    last = if total == 0, do: 0, else: first + assigns.entries_count - 1

    assigns = assign(assigns, range: "#{format_count(first)}–#{format_count(last)}", total: format_count(total))

    ~H"""
    <div class="ak-table-foot">
      <span class="ak-pagination__count">{gettext("%{range} of %{total}", range: @range, total: @total)}</span>
      <.page_links :if={@pagination.total_pages > 1} pagination={@pagination} paths={@paths} link_params={@link_params} />
      <.per_page pagination={@pagination} paths={@paths} link_params={@link_params} options={@per_page_options} />
    </div>
    """
  end

  attr :pagination, :any, required: true
  attr :paths, Paths, required: true
  attr :link_params, :map, required: true

  defp page_links(assigns) do
    %{current_page: current, total_pages: total} = assigns.pagination
    assigns = assign(assigns, items: window(current, total), current: current, total: total)

    ~H"""
    <nav aria-label={gettext("Pagination")}>
      <ul class="ak-pagination__pages">
        <li>
          <.page_link
            page={@current - 1}
            label={gettext("Previous page")}
            icon="hero-chevron-left"
            disabled={@current == 1}
            paths={@paths}
            link_params={@link_params}
          />
        </li>
        <li :for={item <- @items}>
          <span :if={item == :gap} class="ak-page ak-page--gap" aria-hidden="true">…</span>
          <.page_link
            :if={item != :gap}
            page={item}
            label={format_count(item)}
            current={item == @current}
            paths={@paths}
            link_params={@link_params}
          />
        </li>
        <li>
          <.page_link
            page={@current + 1}
            label={gettext("Next page")}
            icon="hero-chevron-right"
            disabled={@current == @total}
            paths={@paths}
            link_params={@link_params}
          />
        </li>
      </ul>
    </nav>
    """
  end

  attr :page, :integer, required: true
  attr :label, :string, required: true
  attr :icon, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :current, :boolean, default: false
  attr :paths, Paths, required: true
  attr :link_params, :map, required: true

  defp page_link(assigns) do
    ~H"""
    <a
      href={((@disabled || @current) && "#") || Paths.for(@paths, :index, query: Map.put(@link_params, "page", @page))}
      class="ak-page"
      aria-current={@current && "page"}
      aria-disabled={@disabled && "true"}
      aria-label={@icon && @label}
      tabindex={@disabled && "-1"}
    >
      <.icon :if={@icon} name={@icon} />
      <span :if={!@icon}>{@label}</span>
    </a>
    """
  end

  attr :pagination, :any, required: true
  attr :paths, Paths, required: true
  attr :link_params, :map, required: true
  attr :options, :list, required: true

  defp per_page(assigns) do
    ~H"""
    <div class="ak-pagination__per-page">
      <label for="ak-per-page">{gettext("Rows per page")}</label>
      <select id="ak-per-page" name="per_page" class="ak-input ak-input--sm" phx-hook="AlkemistPerPage">
        {Phoenix.HTML.Form.options_for_select(@options, @pagination.per_page)}
      </select>
      <noscript>
        <a
          :for={n <- @options}
          href={Paths.for(@paths, :index, query: @link_params |> Map.put("per_page", n) |> Map.delete("page"))}
        >{n}</a>
      </noscript>
    </div>
    """
  end

  @doc """
  The page numbers to show: the first three and last page near the start, the first and
  last three near the end, otherwise the first, the neighbours of the current page and the
  last, with `:gap` where pages are skipped.

      iex> Alkemist.Components.Pagination.window(1, 2785)
      [1, 2, 3, :gap, 2785]

      iex> Alkemist.Components.Pagination.window(50, 100)
      [1, :gap, 49, 50, 51, :gap, 100]

      iex> Alkemist.Components.Pagination.window(3, 4)
      [1, 2, 3, 4]
  """
  @spec window(pos_integer(), non_neg_integer()) :: [pos_integer() | :gap]
  def window(_current, total) when total <= 0, do: []

  def window(current, total) do
    edge = if current <= 3, do: 1..min(3, total)//1, else: []
    tail = if current >= total - 2, do: max(total - 2, 1)..total//1, else: []

    [1, total, current - 1, current, current + 1]
    |> Enum.concat(edge)
    |> Enum.concat(tail)
    |> Enum.filter(&(&1 >= 1 and &1 <= total))
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.chunk_every(2, 1)
    |> Enum.flat_map(fn
      [a, b] when b - a > 1 -> [a, :gap]
      [a | _] -> [a]
    end)
  end
end
