defmodule Alkemist.Export.CSV do
  @moduledoc """
  Creates a CSV String for the export
  """

  @doc """
  Create a new CSV String
  Params:
  * columns - generated columns from Manager.CRUD.Assign
  * entries - fetched entries from Manager.CRUD.Assign
  """
  def create_csv(columns, entries) do
    []
    |> add_header(columns)
    |> add_entries(columns, entries)
    |> CSV.encode(separator: ?;)
    |> Enum.to_list()
    |> to_string()
    |> String.replace("\r\n", "\n")
  end

  defp add_header(rows, columns) do
    cols = Enum.reduce(columns, [], fn({_, _, opts}, cols) ->
      cols ++ [opts[:label]]
    end)
    rows ++ [cols]
  end

  defp add_entries(rows, columns, entries) do
    rows = Enum.reduce(entries, rows, fn(entry, rows) ->
      row = Enum.reduce(columns, [], fn({_, cb, _}, acc) ->
        value = cb.(entry)
        acc ++ [value]
      end)
      rows ++ [row]
    end)
  end

end