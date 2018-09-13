defmodule Alkemist.SearchView do
  @moduledoc """
  This Module contains helper methods to render the filter form
  """
  import Phoenix.HTML.Form
  import Phoenix.HTML.Tag
  import Phoenix.HTML.Link

  def filter_field(form, {field, opts}) do
    opts = Keyword.put_new(opts, :label, Phoenix.Naming.humanize(field))
    field_name = field |> field_key(opts[:type]) |> String.to_atom()
    type = Keyword.get(opts, :type, :string)

    content_tag :div, class: "form-group" do
      [
        label(form, field_name, opts[:label], class: "control-label"),
        input_field(form, field_name, type, opts)
      ]
    end
  end

  defp input_field(form, field, :boolean, opts) do
    opts =
      opts
      |> Keyword.put(:collection, ["true", "false"])
      |> Keyword.put(:type, :select)

    input_field(form, field, :select, opts)
  end

  defp input_field(form, field, :select, opts) do
    collection = Keyword.get(opts, :collection, [])
    select(form, field, collection, class: "form-control", prompt: "Choose...")
  end

  defp input_field(form, field, :date, opts) do
    to_field = String.replace(Atom.to_string(field), "gteq", "lteq") |> String.to_atom()

    [
      text_input(form, field, class: "form-control form-control-sm datepicker"),
      text_input(form, to_field, class: "form-control form-control-sm datepicker")
    ]
  end

  defp input_field(form, field, _type, _opts) do
    text_input(form, field, class: "form-control form-control-sm")
  end

  defp field_key(field, type) do
    case type do
      :boolean -> "#{field}_eq"
      :select -> "#{field}_eq"
      :date -> "#{field}_gteq"
      _ -> "#{field}_ilike"
    end
  end
end
