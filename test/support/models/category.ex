defmodule Alkemist.Category do
  @moduledoc """
  This is a Schema for testing with associations
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field(:name, :string)
    has_many(:posts, Alkemist.Post)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
  end
end
