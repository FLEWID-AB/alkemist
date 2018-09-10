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

    field_opts = get_field_opts(opts, %{class: "form-check-input"})

    content_tag(:div, class: "form-group row") do
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
  def render_form_field(form, {key, %{type: :hidden} = opts} = field) do
    field_opts = get_field_opts(opts, %{})
    hidden_input(form, field, field_opts)
  end

  @doc """
  Renders a text input type
  """
  def render_form_field(form, {key, opts} = field) do
    label = Map.get(opts, :label, Phoenix.Naming.humanize(key))

    content_tag(:div, class: "form-group row") do
      [
        label(form, key, label, class: "control-label col-sm-2 col-form-label"),
        content_tag(:div, class: "col-sm-10") do
          input_element(form, field)
        end
      ]
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

    field_opts = get_field_opts(opts, %{class: "form-check-input"})

    PhoenixMTM.Helpers.collection_checkboxes(
      form,
      key,
      collection,
      input_opts: field_opts,
      selected: selected,
      mapper: &Alkemist.MTM.BootstrapMapper.bootstrap/6
    )
  end

  defp input_element(form, {key, %{type: :select, collection: collection} = opts}) do
    field_opts = get_field_opts(opts, %{class: "form-control", prompt: "Choose..."})

    [
      select(form, key, collection, field_opts),
      error_message(form, key)
    ]
  end

  defp input_element(form, {key, %{type: :password} = opts}) do
    field_opts = get_field_opts(opts, %{class: "form-control"})

    [
      password_input(form, key, field_opts),
      error_message(form, key)
    ]
  end

  defp input_element(form, {key, opts}) do
    field_opts = get_field_opts(opts, %{class: "form-control"})

    [
      text_input(form, key, field_opts),
      error_message(form, key)
    ]
  end

  defp error_message(form, key) do
    err = error_tag(form, key)

    if Enum.empty?(err) do
      []
    else
      Enum.map(err, fn {_, msg} -> msg end)
    end
  end

  defp get_field_opts(opts, defaults) do
    defaults
    |> Map.merge(opts)
    |> Map.delete(:type)
    |> Map.delete(:collection)
    |> Map.delete(:label)
    |> Enum.map(fn({k,v}) -> {k,v} end) # back to keyword

  end
end