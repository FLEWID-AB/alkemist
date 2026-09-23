defmodule Alkemist.Tag do
  @moduledoc "Fixture schema for many_to_many association filters."
  use Ecto.Schema
  import Ecto.Changeset

  schema "tags" do
    field(:name, :string)
    many_to_many(:posts, Alkemist.Post, join_through: "posts_tags")

    timestamps()
  end

  @doc false
  def changeset(tag, params \\ %{}) do
    tag
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end
