defmodule Alkemist.Query.PaginationProvider do
  @moduledoc """
  Behaviour for the module that paginates the filtered query. Configure with
  `config :my_app, Alkemist, query: [paginate: MyApp.Paginate]` or pass
  `pagination_provider:` to `render_index`.

  `opts` always contains `:repo`, `:schema` and `:otp_app`.
  """

  @callback run(Ecto.Queryable.t(), params :: map(), opts :: keyword()) ::
              {Ecto.Query.t(), Alkemist.Query.Page.t()}
end
