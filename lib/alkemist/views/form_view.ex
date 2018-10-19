defmodule Alkemist.FormView do
  @moduledoc """
  This module contains helper methods to render the new and
  edit forms
  """

  import Phoenix.HTML.Form
  import Phoenix.HTML.Tag
  import Alkemist.ErrorHelpers

  @doc """
  Renders a boolean input field
  """
  def render_form_field(form, {key, %{type: :boolean} = opts}) do
    label = Map.get(opts, :label, Phoenix.Naming.humanize(key))

    field_opts = get_field_opts(opts, %{class: "custom-control custom-checkbox"})
    group_class = "form-group row"
    group_class = case Keyword.get(field_opts, :required) do
      true -> group_class <> " required"
      _ -> group_class
    end

    content_tag(:div, class: group_class) do
      [
        content_tag(:div, "", class: "col-sm-2"),
        content_tag(:div, class: "col-sm-10") do
          content_tag(:div, class: "form-check") do
            [
              checkbox(form, key, field_opts),
              label(form, key, label, class: "form-check-label")
            ]
          end
        end
      ]
    end
  end

  @doc """
  Renders a hidden form field
  """
  def render_form_field(form, {key, %{type: :hidden} = opts}) do
    field_opts = get_field_opts(opts, %{})
    hidden_input(form, key, field_opts)
  end

  @doc """
  Renders a has_many relationship.
  Please ensure you add the resources to preload
  """
  def render_form_field(form, {_key, %{type: :has_many, fields: _fields}} = field) do
    template = build_empty_form_template(form, field)
    content_tag(:div, class: "alkemist_hm--container", "data-template": template) do
      [
        content_tag(:div, class: "alkemist_hm--groups") do
          render_has_many_inputs(form, field)
        end,
        content_tag(:div, class: "row justify-content-end button-row") do
          content_tag(:a, "Add new", href: "#", class: "btn btn-secondary alkemist_hm--add")
        end
      ]
    end
  end

  defp render_has_many_inputs(form, {key, %{fields: fields} = opts}, new_record \\ false) do
    field_opts = get_field_opts(opts, %{})
    inputs_for(form, key, field_opts, fn f ->
      content_tag(:div, class: "alkemist_hm--group", "data-field": "#{key}") do
        if new_record == true do
          [content_tag(:a, Phoenix.HTML.raw("&times;"), href: "#", class: "close") | Enum.map(Keyword.delete(fields, :_destroy), fn field -> render_form_field(f, field) end)]
        else
          Enum.map(fields, fn field -> render_form_field(f, field) end)
        end
      end
    end)
  end

  @doc """
  Renders a text input type
  """
  def render_form_field(form, {key, opts} = field) do
    label = Map.get(opts, :label, Phoenix.Naming.humanize(key))
    group_class = "form-group"
    group_class = case Map.get(opts, :required) do
      true -> group_class <> " required"
      _ -> group_class
    end
    content_tag(:div, class: group_class) do
      content_tag(:div, class: "input-group") do
        [
          content_tag(:div, class: "input-group-prepend") do
            content_tag(:span, class: "input-group-text equalWidth") do
              label
            end
          end,
          input_element(form, field)
        ]
      end
    end
  end

  defp input_element(form, {key, %{type: :many_to_many, collection: collection} = opts}) do
    selected =
      case Map.get(form.data, key) do
        a when is_list(a) ->
          Enum.map(a, & &1.id)

        _ ->
          []
      end

    field_opts = get_field_opts(opts, %{class: "custom-control-input"})
    content_tag(:div, class: "form-control checkboxes") do
      PhoenixMTM.Helpers.collection_checkboxes(
        form,
        key,
        collection,
        input_opts: field_opts,
        selected: selected,
        mapper: &Alkemist.MTM.BootstrapMapper.bootstrap/6
      )
    end
  end

  defp input_element(form, {key, %{type: :select, collection: collection} = opts}) do
    field_opts = get_field_opts(opts, %{class: "form-control", prompt: "Choose..."})

    [
      select(form, key, collection, field_opts),
      error_tag(form, key)
    ]
  end

  defp input_element(form, {key, %{type: :select_multi, collection: collection} = opts}) do
    field_opts = get_field_opts(opts, %{class: "form-control", prompt: "Choose..."})
    [
      multiple_select(form, key, collection, field_opts),
      error_tag(form, key)
    ]
  end

  defp input_element(form, {key, %{type: :password} = opts}) do
    field_opts = get_field_opts(opts, %{class: "form-control"})

    [
      password_input(form, key, field_opts),
      error_tag(form, key)
    ]
  end

  defp input_element(form, {key, %{type: :text} = opts}) do
    field_opts = get_field_opts(opts, %{class: "form-control"})

    [
      textarea(form, key, field_opts),
      error_tag(form, key)
    ]
  end

  defp input_element(form, {key, %{type: :number} = opts}) do
    field_opts = get_field_opts(opts, %{class: "form-control"})
    [
      number_input(form, key, field_opts),
      error_tag(form, key)
    ]
  end

  defp input_element(form, {key, %{type: :date} = opts}) do
    field_opts = get_field_opts(opts, %{class: "form-control datepicker"})
    [
      text_input(form, key, field_opts),
      error_tag(form, key)
    ]
  end

  defp input_element(form, {key, opts}) do
    field_opts = get_field_opts(opts, %{class: "form-control"})

    [
      text_input(form, key, field_opts),
      error_tag(form, key)
    ]
  end

  defp get_field_opts(opts, defaults) do
    defaults
    |> Map.merge(opts)
    |> Map.delete(:type)
    |> Map.delete(:collection)
    |> Map.delete(:label)
    |> Map.delete(:fields)
    |> Enum.map(fn({k,v}) -> {k,v} end) # back to keyword

  end

  # Used to build the new forms for the has_many associations
  defp build_empty_form_template(form, {key, _opts} = field) do
    case Alkemist.Utils.get_association(form.data, key) do
      %{cardinality: :many, queryable: queryable} ->
        source = form.source
        data = source.data.__struct__.__struct__
        |> Map.put(key, [queryable.__struct__])

        source = Map.put(source, :data, data)
        form = Map.put(form, :source, source)
        Phoenix.HTML.safe_to_string(render_has_many_inputs(form, field, true))
        |> String.replace("#{key}_0", "#{key}_$index")
        |> String.replace("[#{key}][0]", "[#{key}][$index]")

      _ ->
        ""
    end
  end
end
