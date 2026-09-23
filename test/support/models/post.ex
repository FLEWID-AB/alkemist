defmodule Alkemist.Post do
  @moduledoc """
  Fixture schema exercising the field types Alkemist renders and filters:
  strings, booleans, integers, decimals, naive datetimes, a `belongs_to` and a
  `many_to_many`.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field(:title, :string)
    field(:body, :string)
    field(:published, :boolean, default: false)
    field(:views, :integer)
    field(:price, :decimal)
    field(:published_at, :naive_datetime)
    belongs_to(:category, Alkemist.Category)
    many_to_many(:tags, Alkemist.Tag, join_through: "posts_tags", on_replace: :delete)

    timestamps()
  end

  @doc false
  def changeset(post, params \\ %{}) do
    post
    |> cast(params, [:title, :body, :published, :views, :price, :published_at, :category_id])
    |> validate_required([:title])
  end
end
