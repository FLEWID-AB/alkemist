defmodule Alkemist.Utils do
  @moduledoc """
  Provides some helper functions for the CRUD actions
  """

  @doc ~S"""
  converts a string from lowercase with lowdashes
  to a readable Label

  ## Examples:

    iex> Utils.to_label(:my_model)
    "My Model"

    iex> Utils.to_label("my_model")
    "My Model"

    iex> Utils.to_label(nil)
    ""
  """
  def to_label(val) do
    "#{val}"
    |> String.split("_")
    |> Enum.map(&Inflex.camelize/1)
    |> Enum.join(" ")
  end

  @doc ~S"""
  Returns the struct name as atom

  ## Examples:

    iex> Utils.get_struct(Alkemist.Post)
    :post

    iex> Utils.get_struct(%Alkemist.Post{})
    :post
  """
  def get_struct(resource) when is_map(resource) do
    get_struct(resource.__struct__)
  end

  def get_struct(resource) do
    source =
      resource.__schema__(:source)
      |> Inflex.singularize()

    String.to_atom(source)
  end

  @doc ~S"""
  Returns the singular name for an Ecto Schema

  ## Examples:

    iex> Utils.singular_name(%Alkemist.Post{})
    "Post"

    iex> Utils.singular_name(Alkemist.Post)
    "Post"
  """
  def singular_name(resource) when is_map(resource), do: singular_name(resource.__struct__)

  def singular_name(resource) do
    resource.__schema__(:source)
    |> Inflex.singularize()
    |> to_label()
  end

  @doc ~S"""
  Returns the plural name for an Ecto Schema

  ## Examples:

    iex> Utils.plural_name(%Alkemist.Post{})
    "Posts"

    iex> Utils.plural_name(Alkemist.Post)
    "Posts"
  """
  def plural_name(resource) when is_map(resource), do: plural_name(resource.__struct__)

  def plural_name(resource) do
    resource.__schema__(:source)
    |> Inflex.pluralize()
    |> to_label()
  end
end
