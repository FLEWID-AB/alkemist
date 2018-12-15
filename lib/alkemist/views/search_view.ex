defmodule Alkemist.SearchView do
  @moduledoc """
  This Module contains helper methods to render the filter form
  """
  import Phoenix.HTML.Form
  import Phoenix.HTML.Tag

  @doc """
  Renders a filter field for the search form

  ## Example:

  ```elixir
    filter_field(form, {:category_id, [type: :select, collection: @categories]})
  ```
  """
  def filter_field(form, {field, opts}) do
    opts =
      opts
      |> Keyword.put_new(:label, Phoenix.Naming.humanize(field))
      |> Keyword.put_new(:decorator, Alkemist.Config.filter_decorator())

    field_name = field |> field_key(opts[:type]) |> String.to_atom()
    type = Keyword.get(opts, :type, :string)

    {mod, fun} = opts[:decorator]
    apply(mod, fun, [form, field_name, type, opts])
  end

  def filter_field_decorator(form, field_name, type, opts) do
    primary = opts[:primary] || false
    content_tag :div, class: "form-group #{hide_class(primary)}" do
      [
        label(form, field_name, opts[:label], class: "control-label"),
        input_field(form, field_name, type, opts)
      ]
    end
  end

  def round_filter_field(form, {field, opts}) do
    opts        = Keyword.put_new(opts, :label, Phoenix.Naming.humanize(field))
    opts        = Keyword.put_new(opts, :round, true)
    field_name  = field |> field_key(opts[:type]) |> String.to_atom()
    type        = Keyword.get(opts, :type, :string)
    primary     = opts[:primary] || false


    content_tag :div, class: "form-group col-md-4 col-lg-4 #{hide_class(primary)}" do
      content_tag :div, class: "input-group input-group-sm placeholder-fa" do
        [
          content_tag :div, class: "input-group-prepend" do
            content_tag :span, class: "input-group-text equalWidth" do
              opts[:label]
            end
          end,
          input_field(form, field_name, type, opts)
        ]
      end
    end
  end

  def input_field(form, field, :boolean, opts) do
    opts =
      opts
      |> Keyword.put(:collection, ["true", "false"])
      |> Keyword.put(:type, :select)

    input_field(form, field, :select, opts)
  end

  def input_field(form, field, :select, opts) do
    collection = Keyword.get(opts, :collection, [])
    select(form, field, collection, class: "form-control form-control-sm", prompt: "Choose...")
  end

  def input_field(form, field, :date, _opts) do
    to_field = String.replace(Atom.to_string(field), "gteq", "lteq") |> String.to_atom()
    [
      text_input(form, field, class: "form-control form-control-sm datepicker", placeholder: "From"),
      text_input(form, to_field, class: "form-control form-control-sm datepicker", placeholder: "To")
    ]
  end

  def input_field(form, field, _type, opts) do
    IO.inspect opts
    text_input(form, field, class: "form-control form-control-sm", placeholder: opts[:label])
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
