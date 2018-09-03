defmodule Alkemist.Query.Search do
  @moduledoc """
  Implement Basic search functionality. You can define custom search hooks per module
  """

  def run(query, params) do
    Turbo.Ecto.turboq(query, params)
  end
end
