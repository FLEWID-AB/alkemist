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
  @spec create_csv([Alkemist.Types.Column.t()], [map()]) :: String.t()
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
    cols = Enum.reduce(columns, [], fn(%{label: label}, cols) ->
      cols ++ [label]
    end)
    rows ++ [cols]
  end

  defp add_entries(rows, columns, entries) do
    Enum.reduce(entries, rows, fn(entry, rows) ->
      row = Enum.reduce(columns, [], fn(%{callback: cb}, acc) ->
        value = cb.(entry) |> format()
        acc ++ [value]
      end)
      rows ++ [row]
    end)
  end

  defp format({:safe, _} = content) do
    Phoenix.HTML.safe_to_string(content)
    |> format()
  end

  defp format(content) when is_bitstring(content) do
    content
    |> HtmlSanitizeEx.strip_tags()
  end

  defp format(content), do: format("#{content}")

end
