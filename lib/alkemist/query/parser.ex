defmodule Alkemist.Query.Parser do
  @moduledoc """
  Splits `q[<field>_<operator>]` keys into field name and operator.

  The dialect is the one Alkemist has always accepted (it originated in Turbo.Ecto):

  | suffix | meaning |
  |---|---|
  | `eq`, `neq` | equal, not equal |
  | `lt`, `lteq`, `gt`, `gteq` | comparisons |
  | `in`, `not_in` | membership (list or comma-separated) |
  | `cont`, `ilike` / `not_cont`, `not_ilike` | case-insensitive contains |
  | `start`, `not_start` | case-insensitive starts with |
  | `end`, `not_end` | case-insensitive ends with |
  | `null`, `not_null` | is null / is not null |

  A key without a recognised suffix means "contains". Because a field may itself end
  in an operator word (`end_date`, `status_in`), `split/1` returns every plausible
  reading, longest suffix first, and `Alkemist.Query.Field` picks the first one that
  exists on the schema.
  """

  @operators %{
    "eq" => :eq,
    "neq" => :neq,
    "lt" => :lt,
    "lteq" => :lteq,
    "gt" => :gt,
    "gteq" => :gteq,
    "in" => :in,
    "not_in" => :not_in,
    "cont" => :cont,
    "not_cont" => :not_cont,
    "ilike" => :cont,
    "not_ilike" => :not_cont,
    "start" => :start,
    "not_start" => :not_start,
    "end" => :end,
    "not_end" => :not_end,
    "null" => :null,
    "not_null" => :not_null
  }

  @suffixes @operators |> Map.keys() |> Enum.sort_by(&(-byte_size(&1)))

  @type operator ::
          :eq
          | :neq
          | :lt
          | :lteq
          | :gt
          | :gteq
          | :in
          | :not_in
          | :cont
          | :not_cont
          | :start
          | :not_start
          | :end
          | :not_end
          | :null
          | :not_null

  @doc "All operator atoms."
  @spec operators() :: [operator()]
  def operators, do: @operators |> Map.values() |> Enum.uniq()

  @doc "All accepted suffix strings."
  @spec suffixes() :: [String.t()]
  def suffixes, do: @suffixes

  @doc ~S"""
  Returns candidate `{field, operator}` readings of a key, most specific first.
  The last candidate is always the whole key with the default `:cont` operator.

      iex> Alkemist.Query.Parser.split("title_not_ilike")
      [{"title", :not_cont}, {"title_not", :cont}, {"title_not_ilike", :cont}]

      iex> Alkemist.Query.Parser.split("published_at_gteq")
      [{"published_at", :gteq}, {"published_at_gteq", :cont}]

      iex> Alkemist.Query.Parser.split("title")
      [{"title", :cont}]
  """
  @spec split(String.t()) :: [{String.t(), operator()}]
  def split(key) when is_binary(key) do
    candidates =
      for suffix <- @suffixes,
          String.ends_with?(key, "_" <> suffix),
          field = binary_part(key, 0, byte_size(key) - byte_size(suffix) - 1),
          field != "",
          do: {field, Map.fetch!(@operators, suffix)}

    candidates ++ [{key, :cont}]
  end
end
