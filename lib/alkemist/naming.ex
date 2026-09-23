defmodule Alkemist.Naming do
  @moduledoc """
  Naming helpers for schemas, labels and CSS classes.

  Alkemist derives everything it needs to name a resource from two facts about
  an Ecto schema: its module name and its table (`__schema__(:source)`).

    * the **param key** (`"post"` in `%{"post" => params}`) comes from the module
      name via `Phoenix.Naming.resource_name/1`, which is what `Phoenix.HTML.Form`
      uses as well;
    * the **plural label** ("Posts") is the humanised table name, since tables are
      conventionally plural;
    * the **singular label** ("Post") is the humanised param key.

  No inflection library is involved. Controllers can override the param key with
  a `resource_key/0` callback (see `Alkemist.Controller`).
  """

  @doc ~S"""
  Turns an underscored atom or string into a human label.

      iex> Alkemist.Naming.humanize(:my_model)
      "My Model"

      iex> Alkemist.Naming.humanize("category_id")
      "Category Id"

      iex> Alkemist.Naming.humanize(nil)
      ""
  """
  @spec humanize(atom() | String.t() | nil) :: String.t()
  def humanize(nil), do: ""

  def humanize(value) do
    value
    |> to_string()
    |> String.split("_", trim: true)
    |> Enum.map_join(" ", &upcase_first/1)
  end

  @doc ~S"""
  The param key for a schema module or struct, derived from the module name.

      iex> Alkemist.Naming.resource_key(Alkemist.Post)
      :post

      iex> Alkemist.Naming.resource_key(%Alkemist.UuidItem{})
      :uuid_item
  """
  @spec resource_key(module() | struct()) :: atom()
  def resource_key(%{__struct__: module}), do: resource_key(module)

  def resource_key(module) when is_atom(module) do
    # Module names are a finite, developer-controlled set, so creating an atom here is safe.
    module |> Phoenix.Naming.resource_name() |> String.to_atom()
  end

  @doc ~S"""
  Human singular label for a schema module or struct.

      iex> Alkemist.Naming.singular_label(Alkemist.Post)
      "Post"

      iex> Alkemist.Naming.singular_label(%Alkemist.UuidItem{})
      "Uuid Item"
  """
  @spec singular_label(module() | struct()) :: String.t()
  def singular_label(resource), do: resource |> resource_key() |> humanize()

  @doc ~S"""
  Human plural label for a schema module or struct, from its table name.

      iex> Alkemist.Naming.plural_label(Alkemist.Post)
      "Posts"

      iex> Alkemist.Naming.plural_label(%Alkemist.Category{})
      "Categories"
  """
  @spec plural_label(module() | struct()) :: String.t()
  def plural_label(%{__struct__: module}), do: plural_label(module)
  def plural_label(module) when is_atom(module), do: module.__schema__(:source) |> humanize()

  @doc ~S"""
  A CSS-class-safe slug: lowercase ASCII letters and digits joined by single dashes.

      iex> Alkemist.Naming.slugify("Published At")
      "published-at"

      iex> Alkemist.Naming.slugify(" Är det  klart? ")
      "r-det-klart"

      iex> Alkemist.Naming.slugify(:category_id)
      "category-id"
  """
  @spec slugify(atom() | String.t()) :: String.t()
  def slugify(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  @irregular_plurals %{
    "person" => "people",
    "child" => "children",
    "man" => "men",
    "woman" => "women"
  }

  @doc ~S"""
  A deliberately small English pluraliser, used only for the generator's route hint.

      iex> Alkemist.Naming.pluralize("post")
      "posts"

      iex> Alkemist.Naming.pluralize("category")
      "categories"

      iex> Alkemist.Naming.pluralize("box")
      "boxes"

      iex> Alkemist.Naming.pluralize("person")
      "people"
  """
  @spec pluralize(String.t()) :: String.t()
  def pluralize(word) when is_binary(word) do
    cond do
      Map.has_key?(@irregular_plurals, word) -> @irregular_plurals[word]
      String.ends_with?(word, ["s", "x", "z", "ch", "sh"]) -> word <> "es"
      String.match?(word, ~r/[^aeiou]y$/) -> String.slice(word, 0..-2//1) <> "ies"
      true -> word <> "s"
    end
  end

  defp upcase_first(""), do: ""

  defp upcase_first(word) do
    {first, rest} = String.split_at(word, 1)
    String.upcase(first) <> rest
  end
end
