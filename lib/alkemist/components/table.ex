defmodule Alkemist.Components.Table do
  @moduledoc """
  The index table: caps headers with sort links, an optional batch-selection column, the
  first column as the link to the record, value cells and a "more actions" menu per row.
  Place it in a flush `<.card>`; the pagination bar goes in the same card.
  """
  use Phoenix.Component
  use Gettext, backend: Alkemist.Gettext
  import Alkemist.Components.Icons

  alias Alkemist.Components.Theme
  alias Alkemist.Paths

  @doc "Renders the index table."
  attr :columns, :list, required: true, doc: "normalised `{field, callback, opts}` columns from `Alkemist.Assign`"
  attr :entries, :list, required: true
  attr :paths, Paths, required: true
  attr :link_params, :map, default: %{}
  attr :sort, :any, default: nil, doc: "`{field, direction}` strings or nil"
  attr :member_actions, :list, default: []
  attr :batch, :boolean, default: false
  attr :struct, :atom, required: true
  attr :conn, :any, required: true
  attr :alkemist_app, :atom, default: :alkemist
  attr :theme, :atom, default: nil
  attr :row_id, :any, default: nil, doc: "a function of the row, defaults to `<struct>-<pk>`"
  attr :rest, :global

  def index_table(assigns) do
    data_columns = Enum.reject(assigns.columns, &match?({:selectable_column, _, _}, &1))

    assigns =
      assigns
      |> assign(:data_columns, Enum.with_index(data_columns))
      |> assign(:row_id, assigns.row_id || fn row -> "#{assigns.struct}-#{pk(row)}" end)

    ~H"""
    <div
      class="ak-table-wrap"
      phx-hook={@batch && "AlkemistBatchSelect"}
      id={"#{@struct}-table"}
      data-batch-menu="batch-actions"
    >
      <table class="ak-table" {@rest}>
        <thead>
          <tr>
            <th :if={@batch} scope="col" class="ak-th ak-th--select">
              <input
                type="checkbox"
                class="ak-checkbox__input"
                data-batch-select-all
                aria-label={gettext("Select all rows")}
              />
            </th>
            <.header_cell
              :for={{column, _i} <- @data_columns}
              column={column}
              paths={@paths}
              link_params={@link_params}
              sort={@sort}
            />
            <Theme.member_actions
              :if={@member_actions != []}
              header?
              actions={@member_actions}
              alkemist_app={@alkemist_app}
              theme={@theme}
            />
          </tr>
        </thead>
        <tbody>
          <tr
            :for={row <- @entries}
            id={@row_id.(row)}
            class={Theme.row_class(@alkemist_app, @theme, row, "ak-tr")}
            data-href={Paths.for(@paths, :show, row)}
            phx-hook="AlkemistRowLink"
          >
            <td :if={@batch} class="ak-td ak-td--select">
              <input
                type="checkbox"
                class="ak-checkbox__input"
                name="batch_ids[]"
                value={pk(row)}
                form="batch-action-form"
                data-batch-select
                aria-label={gettext("Select row %{id}", id: pk(row))}
              />
            </td>
            <.cell
              :for={{column, i} <- @data_columns}
              column={column}
              row={row}
              primary={i == 0}
              paths={@paths}
              alkemist_app={@alkemist_app}
              theme={@theme}
            />
            <Theme.member_actions
              :if={@member_actions != []}
              actions={@member_actions}
              resource={row}
              paths={@paths}
              conn={@conn}
              alkemist_app={@alkemist_app}
              theme={@theme}
            />
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc "A header cell; sortable columns link to the toggled sort."
  attr :column, :any, required: true
  attr :paths, Paths, required: true
  attr :link_params, :map, default: %{}
  attr :sort, :any, default: nil

  def header_cell(%{column: {field, _cb, %{sortable: true} = opts}} = assigns) do
    sort_field = to_string(Map.get(opts, :sort_field, field))
    {current_field, current_dir} = assigns.sort || {nil, nil}
    active? = current_field == sort_field
    next_dir = if active? and current_dir == "asc", do: "desc", else: "asc"

    assigns =
      assign(assigns,
        label: to_string(opts[:label]),
        classes: ["ak-th", "ak-th--#{opts[:type]}", Alkemist.Naming.slugify(opts[:label])],
        aria_sort: (active? && ((current_dir == "desc" && "descending") || "ascending")) || "none",
        icon:
          cond do
            active? and current_dir == "desc" -> "hero-chevron-down"
            active? -> "hero-chevron-up"
            true -> "hero-chevron-up-down"
          end,
        href: Paths.for(assigns.paths, :index, query: Map.put(assigns.link_params, "s", "#{sort_field}+#{next_dir}"))
      )

    ~H"""
    <th scope="col" class={@classes} aria-sort={@aria_sort}>
      <a href={@href} class="ak-th__sort" aria-label={gettext("Sort by %{label}", label: @label)}>
        {@label}<.icon name={@icon} />
      </a>
    </th>
    """
  end

  def header_cell(%{column: {_field, _cb, opts}} = assigns) do
    assigns =
      assign(assigns,
        label: to_string(opts[:label]),
        classes: ["ak-th", "ak-th--#{opts[:type]}", Alkemist.Naming.slugify(opts[:label])]
      )

    ~H"""
    <th scope="col" class={@classes}>{@label}</th>
    """
  end

  @doc """
  A data cell. Association columns with `action:` link to the related record; the first
  (`primary`) column links to the row's own record.
  """
  attr :column, :any, required: true
  attr :row, :any, required: true
  attr :primary, :boolean, default: false
  attr :paths, Paths, required: true
  attr :alkemist_app, :atom, default: :alkemist
  attr :theme, :atom, default: nil

  def cell(%{column: {_field, callback, opts}, row: row} = assigns) do
    assoc_record = if opts[:assoc], do: loaded(Map.get(row, opts.assoc))
    value = if opts[:assoc] && is_nil(assoc_record), do: nil, else: callback.(row)

    assoc_link =
      if opts[:action] && opts[:resource] && assoc_record,
        do: Paths.for_schema(assigns.paths, opts.resource, opts.action, assoc_record)

    assigns =
      assign(assigns,
        value: value,
        opts: opts,
        assoc_link: assoc_link,
        self_link: is_nil(assoc_link) && assigns.primary && Paths.for(assigns.paths, :show, row),
        classes: ["ak-td", "ak-td--#{opts[:type]}", Alkemist.Naming.slugify(opts[:label])]
      )

    ~H"""
    <td class={@classes}>
      <a :if={@self_link} href={@self_link} class="ak-td__primary">
        <Theme.value value={@value} column={@opts} row={@row} alkemist_app={@alkemist_app} theme={@theme} />
      </a>
      <a :if={@assoc_link} href={@assoc_link}>
        <Theme.value value={@value} column={@opts} row={@row} alkemist_app={@alkemist_app} theme={@theme} />
      </a>
      <Theme.value
        :if={!@self_link && !@assoc_link}
        value={@value}
        column={@opts}
        row={@row}
        alkemist_app={@alkemist_app}
        theme={@theme}
      />
    </td>
    """
  end

  @doc false
  def pk(%{__struct__: schema} = row) do
    case Alkemist.Schema.primary_key(schema) do
      {:ok, {field, _}} -> Map.get(row, field)
      _ -> nil
    end
  end

  def pk(_), do: nil

  defp loaded(%Ecto.Association.NotLoaded{}), do: nil
  defp loaded(value), do: value
end
