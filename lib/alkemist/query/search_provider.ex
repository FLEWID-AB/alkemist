defmodule Alkemist.Query.SearchProvider do
  @moduledoc """
  Behaviour for the module that turns request params into query filters and sorting.
  Configure with `config :my_app, Alkemist, query: [search: MyApp.Search]` or pass
  `search_provider:` to `render_index`.

  `opts` always contains `:schema` (the resource module), `:otp_app` and `:repo`.
  """

  @callback filter(Ecto.Queryable.t(), params :: map(), opts :: keyword()) :: Ecto.Query.t()
  @callback sort(Ecto.Queryable.t(), params :: map(), opts :: keyword()) :: Ecto.Query.t()
  @callback run(Ecto.Queryable.t(), params :: map(), opts :: keyword()) :: Ecto.Query.t()
end
