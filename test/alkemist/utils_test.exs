defmodule Alkemist.UtilsTest do
  use ExUnit.Case, async: true
  alias TestAlkemist.{Post, Category}
  alias Alkemist.Utils
  doctest Alkemist.Utils

  defmodule Parent do
    use Ecto.Schema

    schema "parents" do
      field :name, :string

      embeds_many :children, Child do
        field :name, :string
        field :age, :integer
      end
    end
  end

  describe "get_embed" do
    test "it returns the embed content" do
      assert %Ecto.Embedded{
        field: :children,
        cardinality: :many
      } = Utils.get_embed(Parent, :children)
    end

    test "it also gets embed when passing a struct" do
      assert %Ecto.Embedded{
        field: :children,
        cardinality: :many
      } = Utils.get_embed(%Parent{}, :children)
    end
  end
end
