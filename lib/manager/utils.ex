defmodule Manager.Utils do
  @moduledoc """
  Provices some helper functions for the CRUD actions
  """

  @doc """
  converts a string from lowercase with lowdashes
  to a readable Label
  Example:
  > to_label(:report_rows)
  Report Rows
  """
  def to_label(val) do
    "#{val}"
    |> String.split("_")
    |> Enum.map(&Inflex.camelize/1)
    |> Enum.join(" ")
  end

  @doc """
  Returns the struct name as atom
  Example:
  > get_struct(Db.User)
  :user
  > get_struct(%User{})
  :user
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

  # Generate the singular name
  def singular_name(resource) when is_map(resource), do: singular_name(resource.__struct__)

  def singular_name(resource) do
    resource.__schema__(:source)
    |> Inflex.singularize()
    |> to_label()
  end

  # Generate the plural name
  def plural_name(resource) when is_map(resource), do: plural_name(resource.__struct__)

  def plural_name(resource) do
    resource.__schema__(:source)
    |> Inflex.pluralize()
    |> to_label()
  end
end
