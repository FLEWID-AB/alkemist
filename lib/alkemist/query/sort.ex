defmodule Alkemist.Query.Sort do
  @moduledoc """
  Parses the `s=<field>+<direction>` sort parameter. `+` is usually decoded to a
  space by the time it reaches Phoenix, so both separators are accepted.
  """
  alias Alkemist.Query.Field

  @directions %{
    "asc" => :asc,
    "desc" => :desc,
    "asc_nulls_last" => :asc_nulls_last,
    "asc_nulls_first" => :asc_nulls_first,
    "desc_nulls_last" => :desc_nulls_last,
    "desc_nulls_first" => :desc_nulls_first
  }

  @type direction ::
          :asc | :desc | :asc_nulls_last | :asc_nulls_first | :desc_nulls_last | :desc_nulls_first

  @doc """
  Resolves a sort string against the schema. Only root columns and columns of
  cardinality-one associations are sortable.

      iex> {:ok, field, dir} = Alkemist.Query.Sort.parse(Alkemist.Post, "title+desc")
      iex> {field.name, dir}
      {:title, :desc}

      iex> {:ok, _field, dir} = Alkemist.Query.Sort.parse(Alkemist.Post, "title desc")
      iex> dir
      :desc

      iex> {:ok, _field, dir} = Alkemist.Query.Sort.parse(Alkemist.Post, "title")
      iex> dir
      :asc

      iex> Alkemist.Query.Sort.parse(Alkemist.Post, "bogus+desc")
      {:error, :unknown_field}

      iex> Alkemist.Query.Sort.parse(Alkemist.Post, "tags_assoc_name+asc")
      {:error, :unsortable}
  """
  @spec parse(module(), term()) ::
          {:ok, Field.t(), direction()} | {:error, :unknown_field | :unsortable | :invalid}
  def parse(schema, string) when is_binary(string) do
    {field_string, direction} =
      case String.split(string, ~r/[+ ]/, parts: 2, trim: true) do
        [f, d] -> {f, Map.get(@directions, d, :asc)}
        [f] -> {f, :asc}
        [] -> {"", :asc}
      end

    with {:ok, field} <- Field.resolve(schema, field_string) do
      case field.assoc do
        nil -> {:ok, field, direction}
        %{cardinality: :one} -> {:ok, field, direction}
        _ -> {:error, :unsortable}
      end
    end
  end

  def parse(_schema, _other), do: {:error, :invalid}
end
