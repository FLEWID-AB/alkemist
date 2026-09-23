defmodule Alkemist.Components.Filters do
  @moduledoc """
  The index filter bar: one search box plus a dropdown button per remaining filter, and
  "Clear". Everything is one GET form, so it emits the same request dialect as before
  (`q[title_ilike]`, `q[published_at_gteq]`/`q[published_at_lteq]`, `q[category_id_eq]`,
  hidden `s` and `scope`) and works without JavaScript.

  The search box is the first filter marked `primary: true`, otherwise the first text
  filter. Set `placeholder:` on it to describe what it searches.
  """
  use Phoenix.Component
  use Gettext, backend: Alkemist.Gettext
  import Alkemist.Components.Icons
  import Alkemist.Components.Core, only: [button: 1]

  alias Alkemist.Components.Theme
  alias Alkemist.Paths

  @text_types [:string, :text, nil]

  @doc "The filter form."
  attr :filters, :list, required: true, doc: "normalised `{field, opts}` filters"
  attr :filter_form, Phoenix.HTML.Form, required: true
  attr :paths, Paths, required: true
  attr :link_params, :map, default: %{}
  attr :search, :boolean, default: false, doc: "whether a search is active (shows Clear)"
  attr :alkemist_app, :atom, default: :alkemist
  attr :theme, :atom, default: nil

  def filter_form(assigns) do
    {search, rest} = split_search(assigns.filters)
    assigns = assign(assigns, search_filter: search, rest: rest)

    ~H"""
    <.form
      :let={f}
      for={@filter_form}
      method="get"
      action={Paths.for(@paths, :index)}
      id="index-search-form"
      class="ak-filters"
      autocomplete="off"
      phx-hook="AlkemistSearchShortcut"
    >
      <input :if={@link_params["s"]} type="hidden" name="s" value={@link_params["s"]} />
      <input :if={@link_params["scope"]} type="hidden" name="scope" value={@link_params["scope"]} />
      <.search_box :if={@search_filter} form={f} filter={@search_filter} />
      <Theme.filter_field
        :for={filter <- @rest}
        form={f}
        filter={filter}
        paths={@paths}
        link_params={@link_params}
        alkemist_app={@alkemist_app}
        theme={@theme}
      />
      <.button :if={@search} href={Paths.for(@paths, :index, query: Map.drop(@link_params, ["q", "page"]))} variant="ghost">
        {gettext("Clear")}
      </.button>
      <button type="submit" class="sr-only">{gettext("Search")}</button>
    </.form>
    """
  end

  @doc "The keyboard hint shown next to the filter bar."
  def search_hint(assigns) do
    ~H"""
    <span class="ak-muted" style="font-size: 12px">
      {gettext("Press")} <kbd class="ak-kbd">/</kbd> {gettext("to search")}
    </span>
    """
  end

  attr :form, Phoenix.HTML.Form, required: true
  attr :filter, :any, required: true

  defp search_box(%{filter: {field, opts}} = assigns) do
    name = param_name(field, Map.get(opts, :type, :string))
    label = to_string(opts[:label] || Alkemist.Naming.humanize(field))

    assigns =
      assign(assigns,
        name: name,
        label: label,
        placeholder: opts[:placeholder] || gettext("Search by %{label}", label: String.downcase(label))
      )

    ~H"""
    <div class="ak-search">
      <.icon name="hero-magnifying-glass" />
      <input
        type="search"
        id={"q_#{@name}"}
        name={"q[#{@name}]"}
        value={current(@form, @name)}
        placeholder={@placeholder}
        aria-label={@placeholder}
        class="ak-input"
        data-search-input
      />
    </div>
    """
  end

  @doc """
  One filter as a dropdown button showing its label and current value; the panel holds
  the input and an Apply button that submits the whole form.
  """
  attr :form, Phoenix.HTML.Form, required: true
  attr :filter, :any, required: true, doc: "`{field, opts}`"
  attr :paths, Paths, default: nil
  attr :link_params, :map, default: %{}

  def filter_field(%{filter: {field, opts}} = assigns) do
    type = Map.get(opts, :type, :string)
    name = param_name(field, type)
    label = to_string(opts[:label] || Alkemist.Naming.humanize(field))
    summary = summary(assigns.form, name, type, opts)

    assigns =
      assign(assigns,
        field: field,
        opts: opts,
        type: type,
        name: name,
        label: label,
        summary: summary || gettext("Any"),
        active?: not is_nil(summary)
      )

    ~H"""
    <details class="ak-dropdown ak-dropdown--left" id={"ak-filter-#{@name}"}>
      <summary class={["ak-filter-button", @active? && "ak-filter-button--active"]} aria-haspopup="dialog">
        <span class="ak-filter-button__label">{@label}</span> {@summary}<.icon name="hero-chevron-down" />
      </summary>
      <div class="ak-dropdown__menu" role="dialog" aria-label={@label}>
        <div class="ak-dropdown__panel">
          <.filter_input form={@form} name={@name} type={@type} opts={@opts} label={@label} />
          <.date_presets :if={@type in [:date, :datetime] && @paths} name={@name} paths={@paths} link_params={@link_params} />
          <div><.button type="submit" size="sm">{gettext("Apply")}</.button></div>
        </div>
      </div>
    </details>
    """
  end

  attr :form, Phoenix.HTML.Form, required: true
  attr :name, :string, required: true
  attr :type, :atom, required: true
  attr :opts, :map, required: true
  attr :label, :string, required: true

  defp filter_input(%{type: :boolean} = assigns) do
    ~H"""
    <select id={"q_#{@name}"} name={"q[#{@name}]"} class="ak-input" aria-label={@label}>
      {Phoenix.HTML.Form.options_for_select(
        [{gettext("Any"), ""}, {gettext("Yes"), "true"}, {gettext("No"), "false"}],
        current(@form, @name)
      )}
    </select>
    """
  end

  defp filter_input(%{type: :select} = assigns) do
    ~H"""
    <select id={"q_#{@name}"} name={"q[#{@name}]"} class="ak-input" aria-label={@label}>
      <option value="">{gettext("Any")}</option>
      {Phoenix.HTML.Form.options_for_select(@opts[:collection] || [], current(@form, @name))}
    </select>
    """
  end

  defp filter_input(%{type: :select_multi} = assigns) do
    ~H"""
    <select id={"q_#{@name}"} name={"q[#{@name}][]"} multiple class="ak-input" aria-label={@label}>
      {Phoenix.HTML.Form.options_for_select(@opts[:collection] || [], List.wrap(current(@form, @name)))}
    </select>
    """
  end

  defp filter_input(%{type: type} = assigns) when type in [:date, :datetime] do
    assigns = assign(assigns, :to_name, String.replace_suffix(assigns.name, "_gteq", "_lteq"))

    ~H"""
    <div class="ak-field__range">
      <input
        type="date"
        id={"q_#{@name}"}
        name={"q[#{@name}]"}
        value={current(@form, @name)}
        class="ak-input"
        aria-label={gettext("%{label} from", label: @label)}
      />
      <span class="ak-faint">–</span>
      <input
        type="date"
        id={"q_#{@to_name}"}
        name={"q[#{@to_name}]"}
        value={current(@form, @to_name)}
        class="ak-input"
        aria-label={gettext("%{label} to", label: @label)}
      />
    </div>
    """
  end

  defp filter_input(%{type: type} = assigns) when type in [:integer, :number] do
    ~H"""
    <input
      type="number"
      step="any"
      id={"q_#{@name}"}
      name={"q[#{@name}]"}
      value={current(@form, @name)}
      class="ak-input"
      aria-label={@label}
    />
    """
  end

  defp filter_input(assigns) do
    ~H"""
    <input
      type="search"
      id={"q_#{@name}"}
      name={"q[#{@name}]"}
      value={current(@form, @name)}
      class="ak-input"
      aria-label={@label}
    />
    """
  end

  attr :name, :string, required: true
  attr :paths, Paths, required: true
  attr :link_params, :map, required: true

  defp date_presets(assigns) do
    today = Date.utc_today()
    last_month_end = Date.add(Date.beginning_of_month(today), -1)

    presets = [
      {gettext("Last 30 days"), Date.add(today, -30), today},
      {gettext("Last month"), Date.beginning_of_month(last_month_end), last_month_end},
      {gettext("This year"), Date.new!(today.year, 1, 1), today}
    ]

    to_name = String.replace_suffix(assigns.name, "_gteq", "_lteq")

    links =
      for {label, from, to} <- presets do
        q =
          assigns.link_params
          |> Map.get("q", %{})
          |> Map.merge(%{assigns.name => Date.to_iso8601(from), to_name => Date.to_iso8601(to)})

        {label, Paths.for(assigns.paths, :index, query: assigns.link_params |> Map.put("q", q) |> Map.delete("page"))}
      end

    assigns = assign(assigns, :links, links)

    ~H"""
    <div class="ak-presets">
      <a :for={{label, href} <- @links} href={href} class="ak-preset">{label}</a>
    </div>
    """
  end

  defp current(form, name), do: form.params[name]

  # The human summary of a filter's current value, or nil when it is not set.
  defp summary(form, name, type, opts) do
    case type do
      :boolean ->
        case current(form, name) do
          "true" -> gettext("Yes")
          "false" -> gettext("No")
          _ -> nil
        end

      t when t in [:select, :select_multi] ->
        values = form |> current(name) |> List.wrap() |> Enum.reject(&(&1 in [nil, ""]))
        labels = for v <- values, do: option_label(opts[:collection] || [], v)
        if labels == [], do: nil, else: Enum.join(labels, ", ")

      t when t in [:date, :datetime] ->
        from = present(current(form, name))
        to = present(current(form, String.replace_suffix(name, "_gteq", "_lteq")))

        cond do
          from && to -> "#{from} – #{to}"
          from -> gettext("from %{date}", date: from)
          to -> gettext("until %{date}", date: to)
          true -> nil
        end

      _ ->
        present(current(form, name))
    end
  end

  defp option_label(collection, value) do
    Enum.find_value(collection, to_string(value), fn
      {label, v} -> if to_string(v) == to_string(value), do: to_string(label)
      v -> if to_string(v) == to_string(value), do: to_string(v)
    end)
  end

  defp present(v) when v in [nil, ""], do: nil
  defp present(v), do: v

  @doc false
  def split_search(filters) do
    search =
      Enum.find(filters, fn {_f, o} -> o[:primary] == true end) ||
        Enum.find(filters, fn {_f, o} -> Map.get(o, :type) in @text_types end)

    {search, List.delete(filters, search)}
  end

  @doc """
  The `q` key for a filter: `_eq` for booleans, selects and numbers, `_gteq` for dates
  (the "to" input uses `_lteq`), `_ilike` for everything else.
  """
  @spec param_name(atom() | String.t(), atom()) :: String.t()
  def param_name(field, type) when type in [:boolean, :select, :select_multi, :integer, :number], do: "#{field}_eq"
  def param_name(field, type) when type in [:date, :datetime], do: "#{field}_gteq"
  def param_name(field, _type), do: "#{field}_ilike"
end
