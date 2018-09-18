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

  def round_filter_field(form, {field, opts}) do
    opts        = Keyword.put_new(opts, :label, Phoenix.Naming.humanize(field))
    field_name  = field |> field_key(opts[:type]) |> String.to_atom()
    type        = Keyword.get(opts, :type, :string)
    primary     = opts[:primary] || true


    content_tag :div, class: "form-group col-md-4 col-lg-4 #{hide_class(primary)}" do
      content_tag :div, class: "input-group input-group-sm placeholder-fa" do
        [
          content_tag :div, class: "input-group-prepend" do
            content_tag :span, class: "input-group-text equalWidth" do
              opts[:label]
            end
          end,
          # label(form, field_name, opts[:label], class: "control-label"),
          input_field(form, field_name, type, opts, true)
        ]
      end
    end
  end

  defp input_field(form, field, :boolean, opts, _round) do
    opts =
      opts
      |> Keyword.put(:collection, ["true", "false"])
      |> Keyword.put(:type, :select)

    input_field(form, field, :select, opts)
  end

  defp input_field(form, field, :select, opts, _round) do
    collection = Keyword.get(opts, :collection, [])
    select(form, field, collection, class: "form-control form-control-sm", prompt: "Choose...")
  end

  defp input_field(form, field, :date, opts, round \\ false) do
    to_field = String.replace(Atom.to_string(field), "gteq", "lteq") |> String.to_atom()
    content = if round do
      [
        text_input(form, field, class: "form-control form-control-sm datepicker"),
        text_input(form, to_field, class: "form-control form-control-sm datepicker")
      ]
    else
      content_tag(:div, class: "row") do
        [
          content_tag(:div, class: "col") do
            text_input(form, field, class: "form-control form-control-sm datepicker")
          end,
          content_tag(:div, class: "col") do
            text_input(form, to_field, class: "form-control form-control-sm datepicker")
          end
        ]
      end
    end
    content
  end

  defp input_field(form, field, _type, _opts, _round) do
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

  defp hide_class(primary) do
    case primary do
      false -> "hide hidden-filter"
      _ -> ""
    end
  end
end
