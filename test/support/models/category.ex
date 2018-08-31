defmodule Alkemist.Category do
  @moduledoc """
  This is a Schema for testing with associations
  """

  use Ecto.Schema

  schema "categories" do
    field(:name, :string)
    has_many(:posts, Alkemist.Post)

    timestamps()
  end
end
