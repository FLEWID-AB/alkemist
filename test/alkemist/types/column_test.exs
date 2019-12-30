defmodule Alkemist.Types.ColumnTest do
  use Alkemist.DataCase, async: true
  doctest Alkemist.Types.Column

  alias Alkemist.Types.Column
  alias Alkemist.Post

  describe "map" do
    test "it creates new struct from map" do
      col = %{field: :id}
      assert %Column{field: :id, label: "Id", type: :integer, sortable?: true} = Column.map(col, Post)
    end

    test "it creates new struct from tuple" do
      col = {"Foo", fn _ -> "" end, %{class: "test"}}
      assert %Column{
        field: nil,
        label: "Foo",
        class: "test",
        sortable?: false
      } = Column.map(col, Post)

      col2 = {:title, fn _ -> "" end, %{label: "Custom"}}
      assert %Column{
        label: "Custom",
        type: :string,
        sortable?: true,
        field: :title
      } = Column.map(col2, Post)
    end

    test "it creates new struct from single field" do
      col = :title

      assert %Column{
        field: :title,
        type: :string,
        sortable?: true,
        label: "Title"
      } = Column.map(col, Post)
    end

    test "it will store all additional options in column.opts" do
      col = {"Foo", fn row -> row end, %{action: :show}}

      assert %Column{
        label: "Foo",
        opts: %{
          action: :show
        }
      } = Column.map(col, Post)
    end
  end
end
