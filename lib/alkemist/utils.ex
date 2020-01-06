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
  @spec to_label(any()) :: String.t()
  def to_label(val) do
    "#{val}"
    |> String.split("_")
    |> Enum.map(&Inflex.camelize/1)
    |> Enum.join(" ")
  end

  @doc ~S"""
  Returns the struct name as atom

  ## Examples:

    iex> Utils.get_struct(Post)
    :post

    iex> Utils.get_struct(%Post{})
    :post
  """
  @spec get_struct(module() | map()) :: atom()
  def get_struct(resource) when is_map(resource) do
    get_struct(resource.__struct__)
  end

  def get_struct(resource) do
    source =
      resource.__schema__(:source)
      |> singularize()

    String.to_atom(source)
  end

  # This is a special case because inflex has some issues
  defp singularize(val) when is_bitstring(val) do
    val
    |> Inflex.singularize()
    |> handle_irregular()
  end

  defp handle_irregular(val) do
    regex = ~r/(reser)f/i
    Regex.replace(regex, val, "\\1ve")
  end

  @doc ~S"""
  Returns the singular name for an Ecto Schema

  ## Examples:

    iex> Utils.singular_name(%Post{})
    "Post"

    iex> Utils.singular_name(Post)
    "Post"
  """
  @spec singular_name(module() | map()) :: String.t()
  def singular_name(resource) when is_map(resource), do: singular_name(resource.__struct__)

  def singular_name(resource) do
    resource.__schema__(:source)
    |> singularize()
    |> to_label()
  end

  @doc ~S"""
  Returns the plural name for an Ecto Schema

  ## Examples:

    iex> Utils.plural_name(%Post{})
    "Posts"

    iex> Utils.plural_name(Post)
    "Posts"
  """
  @spec plural_name(module() | map()) :: String.t()
  def plural_name(resource) when is_map(resource), do: plural_name(resource.__struct__)

  def plural_name(resource) do
    resource.__schema__(:source)
    |> Inflex.pluralize()
    |> to_label()
  end

  @doc """
  Removes any empty values from the params

  ## Examples:
    iex> Utils.clean_params(%{"q" => %{"title_like" => ""}, "page" => "1"})
    %{"page" => "1"}
  """
  @spec clean_params(map()) :: map()
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

    iex> Utils.get_association(Category, :posts)
    %Ecto.Association.Has{
             cardinality: :many,
             defaults: [],
             field: :posts,
             on_cast: nil,
             on_delete: :nothing,
             on_replace: :raise,
             owner: Category,
             owner_key: :id,
             queryable: Post,
             related: Post,
             related_key: :category_id,
             relationship: :child,
             unique: true
           }

    iex> Utils.get_association(%Category{}, :posts)
    %Ecto.Association.Has{
             cardinality: :many,
             defaults: [],
             field: :posts,
             on_cast: nil,
             on_delete: :nothing,
             on_replace: :raise,
             owner: Category,
             owner_key: :id,
             queryable: Post,
             related: Post,
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

  @spec get_embed(map() | module(), atom()) :: Ecto.Embedded.t() | {:error, atom()}
  def get_embed(resource, field) when is_map(resource),
    do: get_embed(resource.__struct__, field)

  def get_embed(resource, field) do
    if field in resource.__schema__(:embeds) do
      resource.__schema__(:embed, field)
    else
      {:error, :invalid_field}
    end
  end

  @doc """
  Returns the default helper method for a resource to get the helper path. This can be overridden on a controller level

  ## Examples

    iex> Utils.default_resource_helper(Post, TestAlkemist.Alkemist)
    :post_path
  """
  @spec default_resource_helper(module() | map(), module()) :: atom()
  def default_resource_helper(resource, implementation) do
    struct = get_struct(resource)
    default_struct_helper(struct, implementation)
  end

  @doc """
  Returns the default helper method based on teh struct

  ## Examples

    iex> Utils.default_struct_helper(:post, TestAlkemist.Alkemist)
    :post_path
  """
  @spec default_struct_helper(atom(), module()) :: atom()
  def default_struct_helper(struct, implementation) do
    prefix = case Alkemist.Config.route_prefix(implementation) do
      nil -> ""
      val -> "#{val}_"
    end
    String.to_atom("#{prefix}#{struct}_path")
  end

  @doc """
  Returns the field type for a field within a schema, defaults to `:string`

  ## Examples

    iex> Utils.get_field_type(nil, Post)
    nil

    iex> Utils.get_field_type(:title, Post)
    :string

    iex> Utils.get_field_type(:title, %Post{})
    :string
  """
  @spec get_field_type(atom() | nil, map() | module()) :: atom() | nil
  def get_field_type(nil, _), do: nil

  def get_field_type(field, resource) when is_map(resource),
    do: get_field_type(field, resource.__struct__)

  def get_field_type(field, resource) do
    case resource.__schema__(:type, field) do
      val when val in [:boolean, :integer, :date, :datetime, :float, :naive_datetime] -> val
      {:embed, _} -> :embed
      :id -> if field == :id do
        :integer
      else
        :select
      end
      _ -> :string
    end
  end

  @doc """
  Returns the default display fields (for tables) from a schema

  ## Examples

    iex> Alkemist.Utils.display_fields(Post)
    [:id, :title, :body, :published, :category_id]
  """
  @spec display_fields(module()) :: [atom()]
  def display_fields(resource) do
    resource.__schema__(:fields)
    |> Enum.reject(& &1 in [:inserted_at, :updated_at])
  end

  @doc """
  Returns the editable fields for a resource (for forms)

  ## Examples

    iex> Alkemist.Utils.editable_fields(Post)
    [:title, :body, :published, :category_id]
  """
  @spec editable_fields(module()) :: [atom()]
  def editable_fields(resource) do
    resource
    |> display_fields()
    |> Enum.reject(& &1 == :id)
  end
end
