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
  def to_label(val), do: Alkemist.Naming.humanize(val)

  @doc ~S"""
  Returns the struct name as atom

  ## Examples:

    iex> Utils.get_struct(Alkemist.Post)
    :post

    iex> Utils.get_struct(%Alkemist.Post{})
    :post
  """
  def get_struct(resource), do: Alkemist.Naming.resource_key(resource)

  @doc ~S"""
  Returns the singular name for an Ecto Schema

  ## Examples:

    iex> Utils.singular_name(%Alkemist.Post{})
    "Post"

    iex> Utils.singular_name(Alkemist.Post)
    "Post"
  """
  def singular_name(resource), do: Alkemist.Naming.singular_label(resource)

  @doc ~S"""
  Returns the plural name for an Ecto Schema

  ## Examples:

    iex> Utils.plural_name(%Alkemist.Post{})
    "Posts"

    iex> Utils.plural_name(Alkemist.Post)
    "Posts"
  """
  def plural_name(resource), do: Alkemist.Naming.plural_label(resource)

  @doc """
  Removes any empty values from the params

  ## Examples:
    iex> Utils.clean_params(%{"q" => %{"title_like" => ""}, "page" => "1"})
    %{"page" => "1"}
  """
  def clean_params(params) do
    nil_values = [nil, %{}, [], ""]

    params
    |> Map.to_list()
    |> Enum.reduce([], fn {k, v}, acc ->
      if v in nil_values do
        acc
      else
        if is_map(v) do
          value = clean_params(v)

          if value in nil_values do
            acc
          else
            acc ++ [{k, value}]
          end
        else
          acc ++ [{k, v}]
        end
      end
    end)
    |> Enum.into(%{})
  end

  @doc """
  Returns association information for a field in a resource or struct

  ## Examples:

    iex> Utils.get_association(Alkemist.Category, :posts)
    %Ecto.Association.Has{
             cardinality: :many,
             defaults: [],
             field: :posts,
             on_cast: nil,
             on_delete: :nothing,
             on_replace: :raise,
             owner: Alkemist.Category,
             owner_key: :id,
             queryable: Alkemist.Post,
             related: Alkemist.Post,
             related_key: :category_id,
             relationship: :child,
             unique: true
           }

    iex> Utils.get_association(%Alkemist.Category{}, :posts)
    %Ecto.Association.Has{
             cardinality: :many,
             defaults: [],
             field: :posts,
             on_cast: nil,
             on_delete: :nothing,
             on_replace: :raise,
             owner: Alkemist.Category,
             owner_key: :id,
             queryable: Alkemist.Post,
             related: Alkemist.Post,
             related_key: :category_id,
             relationship: :child,
             unique: true
           }
  """
  @spec get_association(map() | struct(), atom()) :: struct()
  def get_association(resource, field) when is_map(resource),
    do: get_association(resource.__struct__, field)

  def get_association(resource, field) do
    if field in resource.__schema__(:associations) do
      resource.__schema__(:association, field)
    else
      {:error, :invalid_field}
    end
  end

  def get_embed(resource, field) when is_map(resource),
    do: get_embed(resource.__struct__, field)

  def get_embed(resource, field) do
    if field in resource.__schema__(:embeds) do
      resource.__schema__(:embed, field)
    else
      {:error, :invalid_field}
    end
  end
end
