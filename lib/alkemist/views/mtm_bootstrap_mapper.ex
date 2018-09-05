defmodule Alkemist.MTM.BootstrapMapper do
  @moduledoc """
  Show checkboxes for many to many collections wrapped in Bootstrap
  markup
  """
  use PhoenixMTM.Mappers

  @doc false
  def bootstrap(form, field, input_opts, label_content, label_opts, _opts) do
    input_opts = Keyword.put_new(input_opts, :class, "form-check-input")
    label_opts = Keyword.put_new(label_opts, :class, "form-check-label")
    content_tag(:div, class: "form-check") do
      [
        tag(:input, input_opts),
        label(form, field, label_opts) do
          html_escape(label_content)
        end
      ]
    end
  end
end