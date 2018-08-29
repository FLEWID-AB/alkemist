defmodule Alkemist.SearchView do
  @moduledoc """
  This Module contains helper methods to render the filter form
  """
  import Phoenix.HTML.Form
  import Phoenix.HTML.Tag
  import Phoenix.HTML.Link

  @doc """
  This macro includes the helper function to build
  the manager filter view.
  """
  def filter_form(conn, rummage, opts \\ []) do
    has_rummage = Map.has_key?(conn.params, "rummage")
    search = rummage["search"]

    sort =
      if has_rummage && conn.params["rummage"]["sort"] != %{},
        do: Poison.encode!(rummage["sort"]),
        else: ""

    scope = if conn.params["scope"], do: conn.params["scope"], else: ""
    filters = Keyword.fetch!(opts, :filters)

    path =
      apply(Alkemist.Config.router_helpers(), String.to_atom("#{opts[:struct]}_path"), [
        conn,
        :index
      ])

    form_for(conn, path, [as: :rummage, method: :get, class: "form", autocomplete: "off"], fn f ->
      {
        :safe,
        elem(hidden_input(f, :sort, value: sort), 1) ++
          elem(tag(:input, type: "hidden", value: scope, name: "scope"), 1) ++
          elem(
            inputs_for(f, :search, fn s ->
              {:safe, inner_form(s, filters, search)}
            end),
            1
          ) ++
          elem(link("Reset", to: path, class: "btn btn-link"), 1) ++
          elem(submit("Search", class: "btn btn-primary btn-sm"), 1)
      }
    end)
  end

  defp inner_form(s, filters, search) do
    filters
    |> form_group(s, search, [])
    |> Enum.reduce([], &(&2 ++ &1))
  end

  defp form_group([filter | tail], s, search, results) do
    field = elem(filter, 0)
    opts = elem(filter, 1)
    label = opts[:label] || Phoenix.Naming.humanize(field)
    type = opts[:type] || :string

    field_value =
      case type do
        :date ->
          [
            start: search[Atom.to_string(field)]["search_term_start"],
            end: search[Atom.to_string(field)]["search_term_end"]
          ]

        _ ->
          search[Atom.to_string(field)]["search_term"]
      end

    assoc =
      case opts[:assoc] do
        nil -> ""
        assocs -> Enum.join(assocs, " -> ")
      end

    content =
      {:safe,
       elem(label(s, field, label, class: "control-label"), 1) ++
         form_field(s, type, filter, field_value, assoc)}

    form_group(
      tail,
      s,
      search,
      results ++ [elem(content_tag(:div, content, class: "form-group"), 1)]
    )
  end

  defp form_group([], _s, _search, results), do: results

  defp form_field(s, :string, {field, opts}, value, assoc) do
    placeholder = opts[:placeholder] || ""
    search_class = opts[:search_class] || "form-control form-control-sm"

    elem(
      inputs_for(s, field, fn e ->
        {
          :safe,
          elem(hidden_input(e, :search_type, value: :ilike), 1) ++
            elem(hidden_input(e, :assoc, value: assoc), 1) ++
            elem(
              text_input(
                e,
                :search_term,
                value: value,
                class: search_class,
                placeholder: placeholder
              ),
              1
            )
        }
      end),
      1
    )
  end

  defp form_field(s, :select, {field, opts}, value, assoc) do
    collection = opts[:collection] || []
    search_class = opts[:search_class] || "form-control form-control-sm"

    elem(
      inputs_for(s, field, fn e ->
        {:safe,
         elem(hidden_input(e, :search_type, value: :eq), 1) ++
           elem(hidden_input(e, :assoc, value: assoc), 1) ++
           elem(
             select(
               e,
               :search_term,
               collection,
               class: search_class,
               selected: value,
               prompt: "Choose..."
             ),
             1
           )}
      end),
      1
    )
  end

  defp form_field(s, :date, {field, opts}, value, assoc) do
    search_class = opts[:search_class] || "form-control col form-control-sm datepicker"

    elem(
      inputs_for(s, field, fn e ->
        {
          :safe,
          elem(hidden_input(e, :search_type, value: :between), 1) ++
            elem(hidden_input(e, :assoc, value: assoc), 1) ++
            elem(
              content_tag(:div, class: "row") do
                {
                  :safe,
                  elem(
                    text_input(
                      e,
                      :search_term_start,
                      value: value[:start],
                      class: search_class <> " ml-3"
                    ),
                    1
                  ) ++
                    elem(
                      text_input(
                        e,
                        :search_term_end,
                        value: value[:end],
                        class: search_class <> " mr-3"
                      ),
                      1
                    )
                }
              end,
              1
            )
        }
      end),
      1
    )
  end

  defp form_field(s, :boolean, {field, opts}, value, assoc) do
    collection = opts[:collection] || []
    search_class = opts[:search_class] || "form-control form-control-sm"

    elem(
      inputs_for(s, field, fn e ->
        {:safe,
         elem(hidden_input(e, :search_type, value: :eq), 1) ++
           elem(hidden_input(e, :assoc, value: assoc), 1) ++
           elem(
             select(
               e,
               :search_term,
               ["true", "false"],
               class: search_class,
               selected: value,
               prompt: "Choose..."
             ),
             1
           )}
      end),
      1
    )
  end

  defp hidden_elem(form, key, value) do
    if value == "" do
      []
    else
      elem(hidden_input(form, key, value: value), 1)
    end
  end
end
