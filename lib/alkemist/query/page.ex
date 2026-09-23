defmodule Alkemist.Query.Page do
  @moduledoc """
  Pagination state handed to templates as the `:pagination` assign.
  """

  defstruct current_page: 1,
            per_page: 10,
            total_count: 0,
            total_pages: 0,
            next_page: nil,
            prev_page: nil

  @type t :: %__MODULE__{
          current_page: pos_integer(),
          per_page: pos_integer(),
          total_count: non_neg_integer(),
          total_pages: non_neg_integer(),
          next_page: pos_integer() | nil,
          prev_page: pos_integer() | nil
        }

  @doc "Builds a page from the total count, requested page and page size, clamping the page into range."
  @spec new(non_neg_integer(), pos_integer(), pos_integer()) :: t()
  def new(total_count, page, per_page) when total_count >= 0 and page >= 1 and per_page >= 1 do
    total_pages = div(total_count + per_page - 1, per_page)
    page = if total_pages > 0, do: min(page, total_pages), else: 1

    %__MODULE__{
      current_page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages,
      next_page: if(page < total_pages, do: page + 1),
      prev_page: if(page > 1, do: page - 1)
    }
  end

  @doc "The zero-based row offset of the page."
  @spec offset(t()) :: non_neg_integer()
  def offset(%__MODULE__{current_page: page, per_page: per_page}), do: (page - 1) * per_page
end
