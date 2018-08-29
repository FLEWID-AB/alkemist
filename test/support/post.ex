defmodule Manager.Post do
  @moduledoc """
  This is a schema to test various field types
  """
  use Ecto.Schema

  schema "posts" do
    field(:title, :string)
    field(:body, :string)
    field(:published, :boolean)
    belongs_to(:category, Manager.Category)

    timestamps()
  end
end
