defmodule Alkemist.FormView do
  @moduledoc """
  This module contains helper methods to render the new and
  edit forms
  """

  import Phoenix.HTML.Form
  import Phoenix.HTML.Tag
  import Alkemist.ErrorHelpers


  @doc """
  iterates through a changeset and collects all errors
  """
  def error_messages(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn
      {msg, opts} -> String.replace(msg, "%{count}", to_string(opts[:count]))
      msg -> msg
    end)
    |> to_html_list()
    |> Phoenix.HTML.safe_to_string()
  end

  defp to_html_list(errors) when is_map(errors) do
    content_tag(:ul) do
      errors
      |> Map.to_list()
      |> Enum.map(fn e -> to_html_list(e) end)
    end
  end

  defp to_html_list(errors) when is_list(errors) do
    Enum.map(errors, fn e ->
      to_html_list(e)
    end)
  end

  defp to_html_list(errors) when is_bitstring(errors) do
    " " <> errors
  end

  defp to_html_list({field, errors}) do
    content_tag(:li) do
      [content_tag(:span, Phoenix.Naming.humanize(field))] ++
      to_html_list(errors)
    end
  end

  @doc """
  Renders a form field within the new and edit form
  """
  def form_field(form, {field, opts}) do
    opts =
      opts
      |> Map.put_new(:label, Phoenix.Naming.humanize(field))
      |> Map.put_new(:decorator, Alkemist.Config.form_field_decorator())

    {mod, fun} = opts.decorator
    apply(mod, fun, [form, {field, Map.delete(opts, :decorator)}])
  end

  @doc """
  Renders a boolean input field
  """
  def form_field_decorator(form, {key, %{type: :boolean} = opts}) do
    label = Map.get(opts, :label, Phoenix.Naming.humanize(key))

    field_opts = get_field_opts(opts, %{class: "form-check-input"})
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
  def form_field_decorator(form, {key, %{type: :hidden} = opts}) do
    field_opts = get_field_opts(opts, %{})
    hidden_input(form, key, field_opts)
  end

  @doc """
  Renders a has_many relationship.
  Please ensure you add the resources to preload
  """
  def form_field_decorator(form, {key, %{type: :has_many, fields: _fields}} = field) do
    template = build_empty_form_template(:association, form, field)
    content_tag(:fieldset, class: "alkemist_hm--container", "data-template": template) do
      [
        content_tag(:legend, Phoenix.Naming.humanize(key)),
        content_tag(:div, class: "alkemist_hm--groups") do
          render_has_many_inputs(form, field)
        end,
        content_tag(:div, class: "row justify-content-end button-row") do
          content_tag(:a, "Add new", href: "#", class: "btn btn-secondary alkemist_hm--add")
        end
      ]
    end
  end

   @doc """
  Renders a has_one relationship
  Please ensure you add the resource to preload
  """
  def form_field_decorator(form, {key, %{type: :has_one}} = field) do
    template = build_empty_form_template(:association, form, field)
    fields = if Map.get(form.data, key) do
      [content_tag(:div, class: "alkemist_ho--groups") do
        render_has_one_inputs(form, field)
      end]
    else
      [
        content_tag(:div, "", class: "alkemist_ho--groups"),
        content_tag(:div, class: "row justify-content-end button-row") do
          content_tag(:a, "Add", href: "#", class: "btn btn-secondary alkemist_ho--add")
        end
      ]
    end

    content_tag(:div, class: "alkemist_ho--container", "data-template": template) do
      fields
    end
  end

    @doc """
  Renders an array of embeds
  """
  def form_field_decorator(form, {key, %{type: :map_array}} = field) do
    template = build_empty_form_template(:embed, form, field)
    content_tag(:fieldset, class: "alkemist_hm--container", "data-template": template) do
      [
        content_tag(:legend, Phoenix.Naming.humanize(key)),
        content_tag(:div, class: "alkemist_hm--groups") do
          render_has_many_inputs(form, field)
        end,
        content_tag(:div, class: "row justify-content-end button-row") do
          content_tag(:a, "Add new", href: "#", class: "btn btn-secondary alkemist_hm--add")
        end
      ]
    end
  end

  @doc """
  Renders an embed
  """
  def form_field_decorator(form, {key, %{type: :map}} = field) do
    template = build_empty_form_template(:embed, form, field)

    fields = if Map.get(form.data, key) do
      [content_tag(:div, class: "alkemist_ho--groups") do
        render_has_one_inputs(form, field)
      end]
    else
      [
        content_tag(:div, "", class: "alkemist_ho--groups"),
        content_tag(:div, class: "row justify-content-end button-row") do
          content_tag(:a, "Add", href: "#", class: "btn btn-secondary alkemist_ho--add")
        end
      ]
    end

    content_tag(:div, class: "alkemist_ho--container", "data-template": template) do
      fields
    end
  end


  @doc """
  Renders a text input type
  """
  def form_field_decorator(form, {key, opts} = field) do
    label = Map.get(opts, :label, Phoenix.Naming.humanize(key))
    group_class = "form-group row"
    group_class = case Map.get(opts, :required) do
      true -> group_class <> " required"
      _ -> group_class
    end
    content_tag(:div, class: group_class) do
      [
        label(form, key, label, class: "control-label col-sm-2 col-form-label"),
        content_tag(:div, class: "col-sm-10") do
          input_element(form, field)
        end
      ]
    end
  end

  def render_has_many_inputs(form, {key, %{fields: fields} = opts}, new_record \\ false) do
    field_opts = get_field_opts(opts, %{})
    inputs_for(form, key, field_opts, fn f ->
      content_tag(:div, class: "alkemist_hm--group", "data-field": "#{key}") do
        if new_record == true do
          [content_tag(:a, Phoenix.HTML.raw("&times;"), href: "#", class: "close") | Enum.map(Keyword.delete(fields, :_destroy), fn field -> form_field_decorator(f, field) end)]
        else
          Enum.map(fields, fn field -> form_field_decorator(f, field) end)
        end
      end
    end)
  end

  def render_has_one_inputs(form, {key, %{fields: fields} = opts}, new_record \\ false) do
    field_opts = get_field_opts(opts, %{})
    inputs_for(form, key, field_opts, fn f ->
      content_tag(:div, class: "alkemist_ho--group", "data-field": "#{key}") do
        if new_record == true do
          [content_tag(:a, Phoenix.HTML.raw("&times;"), href: "#", class: "close") | Enum.map(Keyword.delete(fields, :_destroy), fn field -> form_field_decorator(f, field) end)]
        else
          Enum.map(fields, fn field -> form_field_decorator(f, field) end)
        end
      end
    end)
  end

  def input_element(form, {key, %{type: :many_to_many, collection: collection} = opts}) do
    selected =
      case Map.get(form.data, key) do
        a when is_list(a) ->
          Enum.map(a, & &1.id)

        _ ->
          []
      end

    field_opts = get_field_opts(opts, %{class: "form-check-input"})
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

  def input_element(form, {key, %{type: :select, collection: collection} = opts}) do
    field_opts = get_field_opts(opts, %{class: "form-control", prompt: "Choose..."})

    [
      select(form, key, collection, field_opts),
      error_tag(form, key)
    ]
  end

  def input_element(form, {key, %{type: :select_multi, collection: collection} = opts}) do
    field_opts = get_field_opts(opts, %{class: "form-control", prompt: "Choose..."})
    [
      multiple_select(form, key, collection, field_opts),
      error_tag(form, key)
    ]
  end

  def input_element(form, {key, %{type: :password} = opts}) do
    field_opts = get_field_opts(opts, %{class: "form-control"})

    [
      password_input(form, key, field_opts),
      error_tag(form, key)
    ]
  end

  def input_element(form, {key, %{type: :text} = opts}) do
    field_opts = get_field_opts(opts, %{class: "form-control"})

    [
      textarea(form, key, field_opts),
      error_tag(form, key)
    ]
  end

  def input_element(form, {key, %{type: :number} = opts}) do
    field_opts = get_field_opts(opts, %{class: "form-control"})
    [
      number_input(form, key, field_opts),
      error_tag(form, key)
    ]
  end

  def input_element(form, {key, %{type: :date} = opts}) do
    field_opts = get_field_opts(opts, %{class: "form-control datepicker"})
    [
      text_input(form, key, field_opts),
      error_tag(form, key)
    ]
  end

  def input_element(form, {key, opts}) do
    field_opts = get_field_opts(opts, %{class: "form-control"})

    [
      text_input(form, key, field_opts),
      error_tag(form, key)
    ]
  end

  def get_field_opts(opts, defaults) do
    defaults
    |> Map.merge(opts)
    |> Map.delete(:type)
    |> Map.delete(:collection)
    |> Map.delete(:label)
    |> Map.delete(:fields)
    |> Map.delete(:decorator)
    |> Enum.map(fn({k,v}) -> {k,v} end) # back to keyword

  end

  # Used to build the new forms for the has_many associations
  defp build_empty_form_template(type, form, {key, _opts} = field) do
    assoc = case type do
      :association -> Alkemist.Utils.get_association(form.data, key)
      :embed ->
        assoc = Alkemist.Utils.get_embed(form.data, key)
    end
    case assoc do
      %{cardinality: :many, queryable: queryable} ->
        source = form.source
        data = source.data.__struct__.__struct__
        |> Map.put(key, [queryable.__struct__])

        source = Map.put(source, :data, data)
        form = Map.put(form, :source, source)
        Phoenix.HTML.safe_to_string(render_has_many_inputs(form, field, true))
        |> String.replace("#{key}_0", "#{key}_$index")
        |> String.replace("[#{key}][0]", "[#{key}][$index]")

      %{cardinality: :one, queryable: queryable} ->
        source = form.source
        data = source.data.__struct__.__struct__
        |> Map.put(key, queryable.__struct__)

        source = Map.put(source, :data, data)
        form = Map.put(form, :source, source)
        Phoenix.HTML.safe_to_string(render_has_one_inputs(form, field, true))

      %{cardinality: :many, related: related} ->
        source = form.source

        source = Map.put(source, :changes, Map.put(%{}, key, [related.__struct__]))
        form = Map.put(form, :source, source)

        Phoenix.HTML.safe_to_string(render_has_many_inputs(form, field, true))
        |> String.replace("#{key}_0", "#{key}_$index")
        |> String.replace("[#{key}][0]", "[#{key}][$index]")

      %{cardinality: :many, related: related} ->
        source = form.source

        source = Map.put(source, :changes, Map.put(%{}, key, related.__struct__))
        form = Map.put(form, :source, source)

        Phoenix.HTML.safe_to_string(render_has_one_inputs(form, field, true))

      _ ->
        ""
    end
  end
end
