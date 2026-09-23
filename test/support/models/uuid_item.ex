defmodule Alkemist.UuidItem do
  @moduledoc "Fixture schema with a binary_id primary key (no integer `id`)."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "uuid_items" do
    field(:name, :string)

    timestamps()
  end

  @doc false
  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end
