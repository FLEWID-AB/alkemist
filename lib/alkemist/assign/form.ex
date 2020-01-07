defmodule Alkemist.Assign.Form do
  @moduledoc """
  This module will use controller defined options and create the needed assigns
  for the new and edit forms
  """
  alias Alkemist.{Utils, Assign.Global}
  @behaviour Alkemist.Assign
  @since "2.0.0"

  @impl Alkemist.Assign
  def assigns(implementation, resource, opts \\ []) do
    opts = default_opts(opts, implementation, resource)
    changeset = generate_changeset(opts)
    fields = map_form_fields(Keyword.get(opts, :fields, []), [], resource, opts)

    [
      struct: Utils.get_struct(resource),
      changeset: changeset,
      form_fields: fields
    ]
    |> Keyword.merge(Keyword.take(opts, [:form_partial, :mod, :resource]))
    |> Keyword.merge(Global.assigns(opts))
    |> Keyword.merge(Keyword.get(opts, :assigns, []))
  end

  @doc """
  Ensures that all needed values are present in the options used by `assign`
  """
  @impl Alkemist.Assign
  def default_opts(opts, implementation, resource) do
    opts
    |> Global.opts(implementation, resource)
    |> Keyword.put_new(:changeset, resource.changeset(resource.__struct__, %{}))
    |> Keyword.put_new(:resource, resource)
    |> Keyword.put_new(:mod, resource.__struct__)
    |> add_fields_and_partial(resource)
  end

  defp add_fields_and_partial(opts, resource) do
    if Keyword.has_key?(opts, :form_partial) do
      {partial, assigns} =
        case Keyword.get(opts, :form_partial) do
          {mod, template, assigns} -> {{mod, template}, assigns}
          {mod, template} -> {{mod, template}, []}
        end

      if Enum.empty?(assigns) do
        Keyword.put(opts, :form_partial, partial)
      else
        assigns = Keyword.merge(Keyword.get(opts, :assigns, []), assigns)

        opts
        |> Keyword.put(:form_partial, partial)
        |> Keyword.put(:assigns, assigns)
      end
    else
      opts
      |> Keyword.put_new(:fields, Utils.editable_fields(resource))
      |> Keyword.put_new(:form_partial, {AlkemistView, "form.html"})
    end
  end


  defp generate_changeset(opts) do
    case opts[:preload] do
      nil ->
        opts[:changeset]

      preloads ->
        changeset = opts[:changeset]
        data = opts[:repo].preload(changeset.data, preloads)

        Map.put(changeset, :data, data)
    end
  end

  # TODO: turn this into types
  def map_form_fields([field|tail], results, resource, opts) when is_map(field) do
    fields =
      Map.get(field, :fields, [])
      |> Enum.map(fn f -> map_form_field(f, resource) end)
      |> filter_fields()

    results = results ++ [Map.put(field, :fields, fields)]
    map_form_fields(tail, results, resource, opts)
  end

  def map_form_fields([field | tail], results, resource, opts) do
    group =
      if Enum.empty?(results) do
        %{title: "#{opts[:singular_name]} Details", fields: []}
      else
        Enum.at(results, 0)
      end

    field = map_form_field(field, resource)

    fields =
      (Map.get(group, :fields, []) ++ [field])
      |> filter_fields()

    results = [Map.put(group, :fields, fields)]

    map_form_fields(tail, results, resource, opts)
  end

  def map_form_fields([], results, _resource, _opts), do: results

  defp map_form_field({field, opts}, resource) do
    opts =
      opts
      |> Map.put_new(:type, Utils.get_field_type(field, resource))

    {field, opts}
  end

  defp map_form_field(field, resource) do
    map_form_field({field, %{}}, resource)
  end

  defp filter_fields(fields) do
    Enum.filter(fields, fn {_f, opts} ->
      Map.get(opts, :type) != :embed
    end)
  end
end
