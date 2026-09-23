defmodule Alkemist.Export.CSV do
  @moduledoc """
  Streams the current index scope and filters as a CSV download.

  Rows are read with `Repo.stream/2` inside a transaction, preloaded in chunks,
  encoded with `NimbleCSV` and sent as a chunked HTTP response, so exports of any size
  run in constant memory.

  Configuration (`config :my_app, Alkemist, csv: [...]`):

    * `:separator` — `:semicolon` (default), `:comma` or `:tab`
    * `:bom` — prepend a UTF-8 byte order mark for Excel (default `false`)
    * `:filename` — a string or a `fn schema -> string end`; default `"<table>-<date>.csv"`
    * `:max_rows` — rows fetched per database round-trip (default 500)

  Per column, `%{export: fn record -> value end}` overrides the cell value used in the
  export; otherwise the column callback's value is used and any HTML is stripped.
  """

  import Ecto.Query, only: [exclude: 2]

  NimbleCSV.define(__MODULE__.Semicolon, separator: ";", escape: "\"", line_separator: "\r\n")
  NimbleCSV.define(__MODULE__.Comma, separator: ",", escape: "\"", line_separator: "\r\n")
  NimbleCSV.define(__MODULE__.Tab, separator: "\t", escape: "\"", line_separator: "\r\n")

  @type column :: {atom() | String.t(), (struct() -> term()), map()}

  @doc """
  Sends `query` as a chunked CSV response.

  `opts` must contain `:repo`; it may contain `:schema`, `:preload`, `:otp_app` and any of
  the configuration keys above to override the config for this response.
  """
  @spec send_stream(Plug.Conn.t(), Ecto.Queryable.t(), [column()], keyword()) :: Plug.Conn.t()
  def send_stream(conn, query, columns, opts) do
    repo = Keyword.fetch!(opts, :repo)
    otp_app = Keyword.get(opts, :otp_app, :alkemist)

    config =
      Keyword.merge(
        Alkemist.Config.csv(otp_app),
        Keyword.take(opts, [:separator, :bom, :filename, :max_rows])
      )

    schema = opts[:schema] || Alkemist.Schema.from_queryable(query, opts)
    dumper = dumper(config[:separator])
    filename = filename(config[:filename], schema)

    conn =
      conn
      |> Plug.Conn.put_resp_content_type("text/csv")
      |> Plug.Conn.put_resp_header("content-disposition", ~s(attachment; filename="#{filename}"))
      |> Plug.Conn.send_chunked(200)

    {:ok, conn} =
      if config[:bom],
        do: Plug.Conn.chunk(conn, :unicode.encoding_to_bom(:utf8)),
        else: {:ok, conn}

    {:ok, conn} =
      repo.transaction(
        fn ->
          [header(columns)]
          |> Stream.concat(rows(query, columns, repo, opts[:preload], config[:max_rows]))
          |> dumper.dump_to_stream()
          |> Stream.chunk_every(50)
          |> Enum.reduce_while(conn, fn lines, conn ->
            case Plug.Conn.chunk(conn, lines) do
              {:ok, conn} -> {:cont, conn}
              {:error, :closed} -> {:halt, conn}
            end
          end)
        end,
        timeout: :infinity
      )

    conn
  end

  @doc """
  Builds the whole CSV in memory. Prefer `send_stream/4`.
  """
  @deprecated "Use send_stream/4"
  @spec create_csv([column()], [struct()], keyword()) :: String.t()
  def create_csv(columns, entries, opts \\ []) do
    dumper = dumper(Keyword.get(opts, :separator, :semicolon))

    [header(columns) | Enum.map(entries, &row(&1, columns))]
    |> dumper.dump_to_iodata()
    |> IO.iodata_to_binary()
  end

  defp header(columns),
    do: Enum.map(columns, fn {_field, _cb, opts} -> to_string(opts[:label]) end)

  defp rows(query, columns, repo, preload, max_rows) do
    query
    |> exclude(:preload)
    |> exclude(:limit)
    |> exclude(:offset)
    |> repo.stream(max_rows: max_rows)
    |> Stream.chunk_every(max_rows)
    |> Stream.flat_map(fn chunk -> if preload, do: repo.preload(chunk, preload), else: chunk end)
    |> Stream.map(&row(&1, columns))
  end

  defp row(entry, columns) do
    Enum.map(columns, fn {_field, callback, opts} ->
      value = if export = opts[:export], do: export.(entry), else: callback.(entry)
      cell(value)
    end)
  end

  defp cell(nil), do: ""
  defp cell({:safe, _} = safe), do: safe |> Phoenix.HTML.safe_to_string() |> strip_tags()
  defp cell(value) when is_binary(value), do: strip_tags(value)
  defp cell(%{__struct__: _} = struct), do: to_string_or_inspect(struct)
  defp cell(value) when is_map(value), do: Jason.encode!(value)
  defp cell(value) when is_list(value), do: Enum.map_join(value, ", ", &cell/1)
  defp cell(value), do: to_string(value)

  defp to_string_or_inspect(struct) do
    if String.Chars.impl_for(struct), do: to_string(struct), else: inspect(struct)
  end

  defp strip_tags(html) do
    if String.contains?(html, "<") do
      case Floki.parse_fragment(html) do
        {:ok, parsed} -> Floki.text(parsed)
        {:error, _} -> html
      end
    else
      html
    end
  end

  defp dumper(:comma), do: __MODULE__.Comma
  defp dumper(:tab), do: __MODULE__.Tab
  defp dumper(_), do: __MODULE__.Semicolon

  defp filename(nil, schema), do: "#{schema.__schema__(:source)}-#{Date.utc_today()}.csv"
  defp filename(fun, schema) when is_function(fun, 1), do: fun.(schema)
  defp filename(name, _schema) when is_binary(name), do: name
end
