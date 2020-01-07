defmodule TestAlkemist.Post do
  @moduledoc """
  This is a schema to test various field types
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field(:title, :string)
    field(:body, :string)
    field(:published, :boolean)
    belongs_to(:category, TestAlkemist.Category)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :body, :published, :category_id])
    |> validate_required([:title])
  end
end
