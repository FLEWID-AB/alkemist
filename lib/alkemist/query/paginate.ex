defmodule Alkemist.Query.Paginate do
  @moduledoc """
  Default `Alkemist.Query.PaginationProvider`.

  Reads `page` and `per_page`, clamps them to the configured limits, runs exactly one
  count query and returns the limited/offset query with an `Alkemist.Query.Page`.

  Configuration (`config :my_app, Alkemist, pagination: [...]`):

    * `:default_per_page` (10)
    * `:max_per_page` (100)
    * `:per_page_options` ([10, 25, 50, 100]) shown in the per-page selector
    * `:scope_counts` (true) whether index scopes show counts
  """
  @behaviour Alkemist.Query.PaginationProvider

  import Ecto.Query
  alias Alkemist.Query.Page

  @impl true
  def run(queryable, params, opts) do
    repo = Keyword.fetch!(opts, :repo)
    config = Alkemist.Config.pagination(Keyword.get(opts, :otp_app, :alkemist))
    params = params || %{}

    per_page =
      params
      |> positive_integer("per_page", :per_page, config[:default_per_page])
      |> min(config[:max_per_page])

    requested_page = positive_integer(params, "page", :page, 1)
    total = Alkemist.Query.count(queryable, repo)
    page = Page.new(total, requested_page, per_page)

    paged =
      queryable
      |> Ecto.Queryable.to_query()
      |> limit(^per_page)
      |> offset(^Page.offset(page))

    {paged, page}
  end

  defp positive_integer(params, key, atom_key, default) do
    value = Map.get(params, key) || Map.get(params, atom_key)

    case value do
      int when is_integer(int) and int > 0 ->
        int

      string when is_binary(string) ->
        case Integer.parse(string) do
          {int, ""} when int > 0 -> int
          _ -> default
        end

      _ ->
        default
    end
  end
end
