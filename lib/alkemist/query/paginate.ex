defmodule Alkemist.Query.Paginate do
  @moduledoc """
  Handles pagination. Expects to return a map with the following structure:

  ```elixir
  %{
    current_page: 1,
    next_page: 2,
    per_page: 10,
    prev_page: nil,
    total_count: 20,
    total_pages: 2
  }
  ```
  """

  def run(query, params, opts \\ []) do
    Turbo.Ecto.get_paginate(query, params, opts)
  end
end
