defmodule Alkemist.Components.Form do
  @moduledoc """
  Form building blocks in the style of Phoenix 1.8's core components, on
  `Phoenix.HTML.FormField`.

  `field/1` renders one Alkemist field definition (`{key, opts}` as produced by
  `Alkemist.Assign`), choosing the input from `opts.type`:

  | type | rendered as |
  |---|---|
  | `:string` (default), `:email`, `:url`, `:tel` | text-like `<input>` |
  | `:text` | `<textarea>` |
  | `:integer`, `:float`, `:number` | `<input type="number">` |
  | `:date`, `:datetime`, `:time` | native date/time inputs |
  | `:boolean` | checkbox with a hidden `false` sentinel |
  | `:password`, `:hidden` | as named |
  | `:select` (+ `collection`) | `<select>` with a prompt |
  | `:select_multi` (+ `collection`) | `<select multiple>` |
  | `:many_to_many` (+ `collection`) | `checkbox_group/1` |
  | `:has_many`, `:map_array` (+ `fields`) | `nested_many/1` |
  | `:has_one`, `:map` (+ `fields`) | `nested_one/1` |

  Any other option (`placeholder`, `required`, `step`, `min`, ...) is passed to the input.
  `component: &MyHTML.custom/1` renders the field with your own function component.
  """
  use Phoenix.Component
  use Gettext, backend: Alkemist.Gettext
  import Alkemist.Components.Icons

  alias Alkemist.Components.Theme

  @internal_opts [
    :type,
    :collection,
    :label,
    :fields,
    :component,
    :format,
    :export,
    :primary,
    :sortable,
    :col,
    :assoc,
    :resource,
    :field,
    :action
  ]
  @passthrough ~w(autocomplete disabled max maxlength min minlength pattern placeholder readonly required rows step accept)a

  @doc "A titled group of fields."
  attr :title, :string, default: nil
  slot :inner_block, required: true

  def field_group(assigns) do
    ~H"""
    <section class="ak-card mb-4">
      <header :if={@title} class="ak-card__header">
        <h2 class="ak-card__title">{@title}</h2>
      </header>
      <div class="ak-card__body ak-form__fields">{render_slot(@inner_block)}</div>
    </section>
    """
  end

  @doc "Renders one Alkemist field definition."
  attr :form, Phoenix.HTML.Form, required: true
  attr :field, :any, required: true, doc: "`{key, opts}`"
  attr :alkemist_app, :atom, default: :alkemist
  attr :theme, :atom, default: nil

  def field(%{field: {key, %{component: component}}} = assigns) when not is_nil(component) do
    assigns =
      assign(
        assigns,
        :rendered,
        call(component, %{form: assigns.form, field: assigns.form[key], key: key, opts: elem(assigns.field, 1)})
      )

    ~H"{@rendered}"
  end

  def field(%{field: {key, opts}} = assigns) do
    type = Map.get(opts, :type, :string)
    label = to_string(Map.get(opts, :label, Alkemist.Naming.humanize(key)))

    assigns =
      assign(assigns,
        key: key,
        opts: opts,
        type: type,
        label: label,
        form_field: assigns.form[key],
        rest: rest_opts(opts)
      )

    ~H"""
    <input
      :if={@type == :hidden}
      type="hidden"
      id={@form_field.id}
      name={@form_field.name}
      value={@opts[:value] || @form_field.value}
    />
    <.nested_many
      :if={@type in [:has_many, :map_array]}
      field={@form_field}
      fields={@opts[:fields] || []}
      label={@label}
      alkemist_app={@alkemist_app}
      theme={@theme}
    />
    <.nested_one
      :if={@type in [:has_one, :map]}
      field={@form_field}
      fields={@opts[:fields] || []}
      label={@label}
      alkemist_app={@alkemist_app}
      theme={@theme}
    />
    <.checkbox_group
      :if={@type == :many_to_many}
      field={@form_field}
      options={@opts[:collection] || []}
      label={@label}
      {@rest}
    />
    <.input
      :if={@type not in [:hidden, :has_many, :map_array, :has_one, :map, :many_to_many, :embed]}
      field={@form_field}
      type={input_type(@type)}
      label={@label}
      options={@opts[:collection]}
      multiple={@type == :select_multi}
      step={if @type in [:float, :number], do: "any"}
      {@rest}
    />
    """
  end

  @doc "A labelled input with errors. `type` is an HTML input type, `select` or `textarea`."
  attr :field, Phoenix.HTML.FormField, required: true
  attr :type, :string, default: "text"
  attr :label, :string, default: nil
  attr :options, :list, default: nil, doc: "for selects, as accepted by `Phoenix.HTML.Form.options_for_select/2`"
  attr :multiple, :boolean, default: false
  attr :prompt, :string, default: nil

  attr :rest, :global,
    include:
      ~w(autocomplete disabled max maxlength min minlength pattern placeholder readonly required rows step accept)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(:errors, Enum.map(errors, &translate_error/1))
    |> assign(:id, field.id)
    |> assign(:name, if(assigns.multiple, do: field.name <> "[]", else: field.name))
    |> assign(:value, field.value)
    |> assign(:label, assigns.label || Alkemist.Naming.humanize(field.field))
    |> render_input()
  end

  defp render_input(%{type: "checkbox"} = assigns) do
    assigns = assign(assigns, :checked, Phoenix.HTML.Form.normalize_value("checkbox", assigns.value))

    ~H"""
    <div class={["ak-field ak-field--checkbox", @errors != [] && "ak-field--invalid"]} phx-feedback-for={@name}>
      <label for={@id} class="ak-checkbox">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="ak-checkbox__input"
          aria-invalid={@errors != [] && "true"}
          aria-describedby={@errors != [] && "#{@id}-error"}
          {@rest}
        />
        <span>{@label}</span>
      </label>
      <.error :for={msg <- @errors} id={@id}>{msg}</.error>
    </div>
    """
  end

  defp render_input(%{type: "select"} = assigns) do
    assigns =
      assign(
        assigns,
        :selected,
        if(assigns.multiple, do: selected_values(assigns.value), else: selected_value(assigns.value))
      )

    ~H"""
    <div class={["ak-field", @errors != [] && "ak-field--invalid"]} phx-feedback-for={@name}>
      <label for={@id} class="ak-label">{@label}<span :if={@rest[:required]} class="ak-required" aria-hidden="true">*</span></label>
      <select
        id={@id}
        name={@name}
        class="ak-input"
        multiple={@multiple}
        aria-invalid={@errors != [] && "true"}
        aria-describedby={@errors != [] && "#{@id}-error"}
        {@rest}
      >
        <option :if={@prompt || !@multiple} value="">{@prompt || gettext("Choose...")}</option>
        {Phoenix.HTML.Form.options_for_select(@options || [], @selected)}
      </select>
      <.error :for={msg <- @errors} id={@id}>{msg}</.error>
    </div>
    """
  end

  defp render_input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class={["ak-field", @errors != [] && "ak-field--invalid"]} phx-feedback-for={@name}>
      <label for={@id} class="ak-label">{@label}<span :if={@rest[:required]} class="ak-required" aria-hidden="true">*</span></label>
      <textarea
        id={@id}
        name={@name}
        class="ak-input ak-input--textarea"
        aria-invalid={@errors != [] && "true"}
        aria-describedby={@errors != [] && "#{@id}-error"}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <.error :for={msg <- @errors} id={@id}>{msg}</.error>
    </div>
    """
  end

  defp render_input(assigns) do
    ~H"""
    <div class={["ak-field", @errors != [] && "ak-field--invalid"]} phx-feedback-for={@name}>
      <label for={@id} class="ak-label">{@label}<span :if={@rest[:required]} class="ak-required" aria-hidden="true">*</span></label>
      <input
        type={@type}
        id={@id}
        name={@name}
        value={if(@type == "password", do: nil, else: Phoenix.HTML.Form.normalize_value(@type, @value))}
        class="ak-input"
        aria-invalid={@errors != [] && "true"}
        aria-describedby={@errors != [] && "#{@id}-error"}
        {@rest}
      />
      <.error :for={msg <- @errors} id={@id}>{msg}</.error>
    </div>
    """
  end

  @doc "One error line under an input."
  attr :id, :string, required: true
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p id={"#{@id}-error"} class="ak-error">
      <.icon name="hero-exclamation-triangle" class="size-4" />{render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  A group of checkboxes for a many-to-many association. Submits `name[]=value` per checked
  box plus an empty `name[]=` so that clearing every box submits an empty list.
  """
  attr :field, Phoenix.HTML.FormField, required: true
  attr :options, :list, required: true, doc: "`[{label, value}]` or a list of values"
  attr :label, :string, default: nil
  attr :checked, :list, default: nil, doc: "defaults to the field's value (records are mapped to their ids)"
  attr :rest, :global, include: ~w(disabled required)

  def checkbox_group(assigns) do
    checked = (assigns.checked || selected_values(assigns.field.value)) |> Enum.map(&to_string/1)

    options =
      Enum.map(assigns.options, fn
        {l, v} -> {l, to_string(v)}
        v -> {to_string(v), to_string(v)}
      end)

    name = assigns.field.name <> "[]"

    assigns =
      assign(assigns,
        checked: checked,
        options: options,
        name: name,
        label: assigns.label || Alkemist.Naming.humanize(assigns.field.field)
      )

    ~H"""
    <fieldset class="ak-field ak-field--group">
      <legend class="ak-label">{@label}</legend>
      <input type="hidden" name={@name} value="" />
      <div class="ak-checkbox-group">
        <label :for={{label, value} <- @options} for={"#{@field.id}_#{value}"} class="ak-checkbox">
          <input
            type="checkbox"
            id={"#{@field.id}_#{value}"}
            name={@name}
            value={value}
            checked={value in @checked}
            class="ak-checkbox__input"
            {@rest}
          />
          <span>{label}</span>
        </label>
      </div>
    </fieldset>
    """
  end

  @doc """
  Nested forms for a `has_many` or embeds-many field. Existing entries render with a
  "remove" checkbox (`<key>_drop[]`, see `Ecto.Changeset.cast_assoc/3` `:drop_param`); new
  entries are added client-side from the `<template>`. A `:_destroy` field in `fields`
  is rendered instead of the drop checkbox for changesets that use that convention.
  """
  attr :field, Phoenix.HTML.FormField, required: true
  attr :fields, :list, required: true, doc: "field definitions for one entry"
  attr :label, :string, default: nil
  attr :alkemist_app, :atom, default: :alkemist
  attr :theme, :atom, default: nil

  def nested_many(assigns) do
    fields = Enum.map(assigns.fields, &normalize_nested_field/1)
    {destroy, fields} = Enum.split_with(fields, fn {k, _} -> k == :_destroy end)

    assigns =
      assign(assigns,
        fields: fields,
        destroy: destroy,
        drop_name: "#{assigns.field.form.name}[#{assigns.field.field}_drop][]",
        blank: blank_form(assigns.field)
      )

    ~H"""
    <fieldset id={"#{@field.id}_nested"} class="ak-nested" phx-hook="AlkemistNestedForm" data-index-placeholder="__INDEX__">
      <legend class="ak-label">{@label}</legend>
      <div data-nested-groups class="ak-nested__groups">
        <.inputs_for :let={f} field={@field}>
          <div class="ak-nested__group" data-nested-group>
            <Theme.form_field :for={fld <- @fields} form={f} field={fld} alkemist_app={@alkemist_app} theme={@theme} />
            <Theme.form_field :for={fld <- @destroy} form={f} field={fld} alkemist_app={@alkemist_app} theme={@theme} />
            <label :if={@destroy == []} class="ak-checkbox ak-nested__remove">
              <input type="checkbox" name={@drop_name} value={f.index} class="ak-checkbox__input" data-nested-drop />
              <span>{gettext("Remove")}</span>
            </label>
          </div>
        </.inputs_for>
      </div>
      <template data-nested-template>
        <div class="ak-nested__group" data-nested-group>
          <Theme.form_field :for={fld <- @fields} form={@blank} field={fld} alkemist_app={@alkemist_app} theme={@theme} />
          <Theme.form_field :for={fld <- @destroy} form={@blank} field={fld} alkemist_app={@alkemist_app} theme={@theme} />
        </div>
      </template>
      <button type="button" class="ak-btn ak-btn--secondary ak-btn--sm" data-nested-add>
        <.icon name="hero-plus" />{gettext("Add")}
      </button>
    </fieldset>
    """
  end

  @doc "Nested form for a `has_one` or embeds-one field, with an Add button when it is empty."
  attr :field, Phoenix.HTML.FormField, required: true
  attr :fields, :list, required: true
  attr :label, :string, default: nil
  attr :alkemist_app, :atom, default: :alkemist
  attr :theme, :atom, default: nil

  def nested_one(assigns) do
    fields = Enum.map(assigns.fields, &normalize_nested_field/1)

    assigns =
      assign(assigns,
        fields: fields,
        present?: not is_nil(assigns.field.value),
        blank: blank_form(assigns.field, false)
      )

    ~H"""
    <fieldset id={"#{@field.id}_nested"} class="ak-nested" phx-hook="AlkemistNestedForm" data-index-placeholder="__INDEX__">
      <legend class="ak-label">{@label}</legend>
      <div data-nested-groups class="ak-nested__groups">
        <.inputs_for :let={f} field={@field}>
          <div class="ak-nested__group" data-nested-group>
            <Theme.form_field :for={fld <- @fields} form={f} field={fld} alkemist_app={@alkemist_app} theme={@theme} />
          </div>
        </.inputs_for>
      </div>
      <template :if={!@present?} data-nested-template>
        <div class="ak-nested__group" data-nested-group>
          <Theme.form_field :for={fld <- @fields} form={@blank} field={fld} alkemist_app={@alkemist_app} theme={@theme} />
        </div>
      </template>
      <button :if={!@present?} type="button" class="ak-btn ak-btn--secondary ak-btn--sm" data-nested-add>
        <.icon name="hero-plus" />{gettext("Add")}
      </button>
    </fieldset>
    """
  end

  @doc "All changeset errors as a list, for the top of the form."
  attr :form, Phoenix.HTML.Form, required: true

  def errors_summary(assigns) do
    errors =
      case assigns.form.source do
        %Ecto.Changeset{} = changeset ->
          changeset |> Ecto.Changeset.traverse_errors(&translate_error/1) |> flatten_errors()

        _ ->
          []
      end

    assigns = assign(assigns, :errors, errors)

    ~H"""
    <div :if={@errors != []} class="ak-alert" role="alert">
      <.icon name="hero-exclamation-triangle" class="mt-0.5" />
      <div>
        <p class="font-semibold">{gettext("Please fix the following errors:")}</p>
        <ul class="list-disc pl-4">
          <li :for={{field, message} <- @errors}>{Alkemist.Naming.humanize(field)} {message}</li>
        </ul>
      </div>
    </div>
    """
  end

  @doc "Translates an Ecto error tuple through the `errors` Gettext domain."
  @spec translate_error({String.t(), keyword()}) :: String.t()
  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(Alkemist.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(Alkemist.Gettext, "errors", msg, opts)
    end
  end

  @doc false
  def input_type(:string), do: "text"
  def input_type(:text), do: "textarea"
  def input_type(type) when type in [:integer, :float, :number], do: "number"
  def input_type(:date), do: "date"
  def input_type(:datetime), do: "datetime-local"
  def input_type(:time), do: "time"
  def input_type(:boolean), do: "checkbox"
  def input_type(:password), do: "password"
  def input_type(type) when type in [:select, :select_multi], do: "select"
  def input_type(type) when type in [:email, :url, :tel, :search, :color], do: to_string(type)
  def input_type(_other), do: "text"

  @doc false
  def rest_opts(opts) do
    opts |> Map.drop(@internal_opts) |> Map.take(@passthrough) |> Map.to_list()
  end

  defp normalize_nested_field({key, opts}) when is_map(opts), do: {key, opts}
  defp normalize_nested_field({key, opts}) when is_list(opts), do: {key, Map.new(opts)}
  defp normalize_nested_field(key) when is_atom(key), do: {key, %{type: :string}}

  # A form for an entry that does not exist yet, named with the __INDEX__ placeholder.
  defp blank_form(%Phoenix.HTML.FormField{form: form, field: key}, many? \\ true) do
    suffix = if many?, do: "[__INDEX__]", else: ""
    Phoenix.Component.to_form(%{}, as: "#{form.name}[#{key}]#{suffix}", id: "#{form.id}_#{key}___INDEX__")
  end

  defp selected_value(%{__struct__: _} = record), do: record |> Alkemist.Components.Table.pk() |> to_string()
  defp selected_value(value), do: value

  defp selected_values(%Ecto.Association.NotLoaded{}), do: []
  defp selected_values(nil), do: []
  defp selected_values(values) when is_list(values), do: Enum.map(values, &selected_value/1)
  defp selected_values(value), do: [selected_value(value)]

  defp flatten_errors(errors, prefix \\ nil) do
    Enum.flat_map(errors, fn
      {field, messages} when is_list(messages) ->
        Enum.flat_map(messages, fn
          msg when is_binary(msg) -> [{join(prefix, field), msg}]
          nested when is_map(nested) -> flatten_errors(nested, join(prefix, field))
        end)

      {field, nested} when is_map(nested) ->
        flatten_errors(nested, join(prefix, field))
    end)
  end

  defp join(nil, field), do: field
  defp join(prefix, field), do: :"#{prefix}_#{field}"

  defp call({mod, fun}, assigns), do: apply(mod, fun, [assigns])
  defp call(fun, assigns) when is_function(fun, 1), do: fun.(assigns)
end
