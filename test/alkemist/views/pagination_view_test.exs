defmodule Alkemist.PaginationViewTest do
  use ExUnit.Case

  alias Alkemist.PaginationView

  setup do
    conn = Phoenix.ConnTest.build_conn() |> Plug.Conn.assign(:implementation, Alkemist.TestImplementation)

    {:ok, conn: conn}
  end

  @paginate %{
    total_pages: 10,
    current_page: 5,
    next_page: 6,
    prev_page: 4,
    per_page: 10,
    total_count: 100
  }

  describe "pagination_links" do
    test "it generates previous and next links", %{conn: conn} do
      links =
        PaginationView.pagination_links(conn, @paginate, Alkemist.Post, [])
        |> Phoenix.HTML.safe_to_string()

      assert links =~ "Previous"
      assert links =~ "Next"
    end

    test "disables links for prev", %{conn: conn} do
      paginate =
        @paginate
        |> Map.put(:prev_page, nil)
        |> Map.put(:current_page, 1)
        |> Map.put(:next_page, 1)

      links =
        PaginationView.pagination_links(conn, paginate, Alkemist.Post, [])
        |> Phoenix.HTML.safe_to_string()

      assert links =~ "Previous"
      assert links =~ "Next"
      assert links =~ "disabled"
    end

    test "disables links for next", %{conn: conn} do
      paginate =
        @paginate
        |> Map.put(:prev_page, 9)
        |> Map.put(:current_page, 10)
        |> Map.put(:next_page, nil)

      links =
        PaginationView.pagination_links(conn, paginate, Alkemist.Post, [])
        |> Phoenix.HTML.safe_to_string()

      assert links =~ "Previous"
      assert links =~ "Next"
      assert links =~ "disabled"
    end
  end
end
