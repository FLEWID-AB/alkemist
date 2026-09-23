defmodule Alkemist.Query.Filter do
  @moduledoc """
  A resolved filter: a `Alkemist.Query.Field`, an operator and a value cast to the
  field's Ecto type.

  Date-only values (`YYYY-MM-DD`) on datetime columns are expanded to half-open
  intervals so that `published_at_eq=2026-01-02` matches the whole day.
  """
  alias Alkemist.Query.{Field, Parser}

  @enforce_keys [:field, :op, :value]
  defstruct [:field, :op, :value]

  @type op :: Parser.operator() | :not_within
  @type t :: %__MODULE__{field: Field.t(), op: op(), value: term()}

  @text_ops [:cont, :not_cont, :start, :not_start, :end, :not_end]
  @list_ops [:in, :not_in]
  @null_ops [:null, :not_null]
  @datetime_types [:naive_datetime, :naive_datetime_usec, :utc_datetime, :utc_datetime_usec]
  @date_only ~r/^\d{4}-\d{2}-\d{2}$/

  @doc """
  Parses every `q` entry against the schema. Unknown fields and values that do not
  cast are dropped; their keys are returned so callers can log them.
  """
  @spec parse_all(module(), map() | nil, keyword()) :: {[t()], ignored_keys :: [String.t()]}
  def parse_all(schema, q, opts \\ [])
  def parse_all(_schema, q, _opts) when not is_map(q), do: {[], []}

  def parse_all(schema, q, opts) do
    Enum.reduce(q, {[], []}, fn {key, raw}, {filters, ignored} ->
      case parse(schema, to_string(key), raw, opts) do
        {:ok, parsed} -> {filters ++ parsed, ignored}
        {:error, _} -> {filters, ignored ++ [to_string(key)]}
      end
    end)
  end

  @doc "Parses one `q` key/value pair into zero or more filters."
  @spec parse(module(), String.t(), term(), keyword()) :: {:ok, [t()]} | {:error, atom()}
  def parse(schema, key, raw, opts \\ []) do
    with {:ok, field, op} <- Field.resolve_key(schema, key) do
      build(field, op, raw, opts)
    end
  end

  @doc "Builds filters for an already resolved field."
  @spec build(Field.t(), Parser.operator(), term(), keyword()) :: {:ok, [t()]} | {:error, atom()}
  def build(%Field{} = field, op, raw, opts \\ []) do
    op = normalize_op(op, raw)

    with {:ok, value} <- cast(field.type, op, raw) do
      {:ok, expand(field, op, value, raw, opts)}
    end
  end

  # A list sent with eq/neq (the multi-select filter form) means membership.
  defp normalize_op(:eq, raw) when is_list(raw), do: :in
  defp normalize_op(:neq, raw) when is_list(raw), do: :not_in
  defp normalize_op(op, _raw), do: op

  defp cast(_type, op, raw) when op in @text_ops do
    case to_string(raw) do
      "" -> {:error, :empty}
      string -> {:ok, string}
    end
  end

  defp cast(_type, op, raw) when op in @null_ops, do: {:ok, truthy?(raw)}

  defp cast(type, op, raw) when op in @list_ops do
    values =
      raw
      |> List.wrap()
      |> Enum.flat_map(&String.split(to_string(&1), ","))
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    case Enum.reduce_while(values, {:ok, []}, fn v, {:ok, acc} ->
           case Ecto.Type.cast(type, v) do
             {:ok, casted} -> {:cont, {:ok, [casted | acc]}}
             _ -> {:halt, {:error, :invalid_value}}
           end
         end) do
      {:ok, []} -> {:error, :empty}
      {:ok, casted} -> {:ok, Enum.reverse(casted)}
      error -> error
    end
  end

  defp cast(type, _op, raw) when type in @datetime_types and is_binary(raw) do
    if Regex.match?(@date_only, raw), do: Date.from_iso8601(raw), else: cast_scalar(type, raw)
  end

  defp cast(type, _op, raw), do: cast_scalar(type, raw)

  defp cast_scalar(type, raw) do
    case Ecto.Type.cast(type, raw) do
      {:ok, value} -> {:ok, value}
      _ -> {:error, :invalid_value}
    end
  end

  # Date-only values on datetime columns become half-open intervals.
  defp expand(%Field{type: type} = field, op, %Date{} = date, _raw, opts)
       when type in @datetime_types do
    start_of_day = start_of_day(type, date, opts)
    next_day = start_of_day(type, Date.add(date, 1), opts)

    case op do
      :eq -> [filter(field, :gteq, start_of_day), filter(field, :lt, next_day)]
      :neq -> [filter(field, :not_within, {start_of_day, next_day})]
      :gteq -> [filter(field, :gteq, start_of_day)]
      :gt -> [filter(field, :gteq, next_day)]
      :lteq -> [filter(field, :lt, next_day)]
      :lt -> [filter(field, :lt, start_of_day)]
    end
  end

  defp expand(field, op, value, _raw, _opts), do: [filter(field, op, value)]

  defp filter(field, op, value), do: %__MODULE__{field: field, op: op, value: value}

  defp start_of_day(type, date, _opts) when type in [:naive_datetime, :naive_datetime_usec],
    do: NaiveDateTime.new!(date, ~T[00:00:00])

  defp start_of_day(_type, date, opts) do
    DateTime.new!(date, ~T[00:00:00], Keyword.get(opts, :timezone, "Etc/UTC"))
  end

  defp truthy?(raw), do: raw in [true, "true", "1", 1, "yes"]
end
