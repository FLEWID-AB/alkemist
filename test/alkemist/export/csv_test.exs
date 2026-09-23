defmodule Alkemist.Export.CSVTest do
  use Alkemist.ConnCase, async: false

  import Ecto.Query, only: [from: 2]
  alias Alkemist.Export.CSV
  alias Alkemist.{Category, Post}

  defp columns do
    [
      {:id, & &1.id, %{label: "Id"}},
      {:title, & &1.title, %{label: "Title"}},
      {:category, &(&1.category && &1.category.name), %{label: "Category"}},
      {:html, fn _ -> {:safe, "<b>bold</b> text"} end, %{label: "Html"}},
      {:price, & &1.price, %{label: "Price", export: fn p -> "#{p.price} SEK" end}}
    ]
  end

  setup %{conn: conn} do
    cat = insert_category!(name: "News")
    insert_post!(title: "First; with semicolon", category_id: cat.id, price: Decimal.new("9.50"))
    insert_post!(title: ~s(Second "quoted"), category_id: cat.id)
    {:ok, conn: Plug.Conn.put_private(conn, :phoenix_router, AlkemistTest.Router)}
  end

  test "streams a chunked, semicolon-separated file with header and stripped html", %{conn: conn} do
    conn = CSV.send_stream(conn, Post, columns(), repo: Repo, preload: [:category])

    assert conn.state == :chunked
    assert conn.status == 200
    assert Plug.Conn.get_resp_header(conn, "content-type") == ["text/csv; charset=utf-8"]
    [disposition] = Plug.Conn.get_resp_header(conn, "content-disposition")
    assert disposition =~ ~r/attachment; filename="posts-\d{4}-\d{2}-\d{2}\.csv"/

    [header | rows] = conn.resp_body |> String.trim() |> String.split("\r\n")
    assert header == "Id;Title;Category;Html;Price"
    assert Enum.any?(rows, &(&1 =~ ~s("First; with semicolon";News;bold text;9.50 SEK)))
    assert Enum.any?(rows, &(&1 =~ ~s("Second ""quoted""";News;bold text; SEK)))
  end

  test "separator, bom and filename can be configured per call", %{conn: conn} do
    conn =
      CSV.send_stream(conn, Category, [{:name, & &1.name, %{label: "Name"}}],
        repo: Repo,
        separator: :comma,
        bom: true,
        filename: "cats.csv"
      )

    assert <<0xEF, 0xBB, 0xBF, "Name\r\nNews\r\n">> = conn.resp_body

    assert Plug.Conn.get_resp_header(conn, "content-disposition") == [
             ~s(attachment; filename="cats.csv")
           ]
  end

  test "large exports are fetched in chunks and preloaded", %{conn: conn} do
    cat = insert_category!(name: "Bulk")
    now = ~N[2026-01-01 00:00:00]

    rows =
      for i <- 1..1200,
          do: %{
            title: "p#{i}",
            category_id: cat.id,
            published: false,
            inserted_at: now,
            updated_at: now
          }

    Repo.insert_all(Post, rows)

    conn = CSV.send_stream(conn, Post, columns(), repo: Repo, preload: [:category], max_rows: 100)
    lines = conn.resp_body |> String.trim() |> String.split("\r\n")
    assert length(lines) == 1 + 2 + 1200
    assert Enum.count(lines, &String.contains?(&1, ";Bulk;")) == 1200
  end

  test "ignores limit and offset on the query", %{conn: conn} do
    conn =
      CSV.send_stream(conn, from(p in Post, limit: 1, offset: 5), columns(),
        repo: Repo,
        preload: [:category]
      )

    assert conn.resp_body |> String.trim() |> String.split("\r\n") |> length() == 3
  end

  test "create_csv/2 still builds the document in memory" do
    posts = Post |> Repo.all() |> Repo.preload(:category)
    csv = CSV.create_csv(columns(), posts)
    assert String.starts_with?(csv, "Id;Title;Category;Html;Price\r\n")
    assert csv =~ "bold text"
  end

  test "export action streams through the controller", %{conn: conn} do
    conn = get(conn, "/categories/export")
    assert conn.state == :chunked
    assert conn.resp_body =~ "News"
  end
end
