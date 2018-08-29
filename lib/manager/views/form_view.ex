defmodule Manager.FormView do
  @moduledoc """
  This module contains helper methods to render the new and
  edit forms
  """

  import Phoenix.HTML.Form
  import Phoenix.HTML.Tag
  import Manager.ErrorHelpers

  # TODO: add form group method
  # TODO: add select, date and boolean support

  @doc """
  Renders a boolean input field
  """
  def render_form_field(form, {key, [type: :boolean] = opts}) do
    label = opts[:label] || humanize(key)

    field_tag = {
      :safe,
      elem(checkbox(form, key, class: "form-check-input"), 1) ++
        elem(label(form, key, label, class: "form-check-label"), 1)
    }

    content = {
      :safe,
      elem(content_tag(:div, "", class: "col-sm-2"), 1) ++
        elem(content_tag(:div, field_tag, class: "col-sm-10 form-check"), 1) ++
        error_message(form, key)
    }

    content_tag(:div, content, class: "form-group row")
  end

  @doc """
  Renders a text input type
  """
  def render_form_field(form, field) do
    key = elem(field, 0)
    opts = elem(field, 1)

    label =
      if opts[:label] do
        label(form, key, opts[:label], class: "control-label col-sm-2 col-form-label")
      else
        label(form, key, class: "control-label col-sm-2 col-form-label")
      end

    content =
      {:safe,
       elem(label, 1) ++
         elem(
           content_tag(:div, input_element(form, field), class: "col-sm-10"),
           1
         )}

    content_tag(:div, content, class: "form-group row")
  end

  defp input_element(form, {key, [type: :select, collection: collection]}) do
    {
      :safe,
      elem(select(form, key, collection, class: "form-control"), 1) ++ error_message(form, key)
    }
  end

  defp input_element(form, {key, [type: :password]}) do
    {
      :safe,
      elem(password_input(form, key, class: "form-control"), 1) ++ error_message(form, key)
    }
  end

  defp input_element(form, {key, _opts}) do
    {
      :safe,
      elem(text_input(form, key, class: "form-control"), 1) ++ error_message(form, key)
    }
  end

  defp error_message(form, key) do
    err = error_tag(form, key)

    if Enum.empty?(err) do
      []
    else
      Enum.map(err, fn {_, msg} -> msg end)
    end
  end
end
