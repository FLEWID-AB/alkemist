defmodule Alkemist.Post do
  @moduledoc """
  This is a schema to test various field types
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field(:title, :string)
    field(:body, :string)
    field(:published, :boolean)
    belongs_to(:category, Alkemist.Category)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :body, :published])
  end
end
