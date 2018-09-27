defmodule Alkemist.Query.Paginate do
  @moduledoc """
  Handles pagination. Expects to return a tuple with the new query and a map with the following structure:

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
    query = Turbo.Ecto.paginateq(query, params)
    pagination = Turbo.Ecto.Hooks.Paginate.get_paginate(query, params, opts)

    {query, pagination}
  end
end
