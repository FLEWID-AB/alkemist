defmodule Alkemist.Paths do
  @moduledoc """
  Path building for a resource, ready to hand to components.

  A `%Alkemist.Paths{}` captures the conn, the controller and the nested `route_params`
  once (in `Alkemist.Assign`), so components never touch the router or the conn
  themselves. In a LiveView the same struct can be built from the socket's router.

      paths = Alkemist.Paths.new(conn, MyAppWeb.PostController, [category_id])
      Alkemist.Paths.for(paths, :index)                       # "/categories/3/posts"
      Alkemist.Paths.for(paths, :show, post)                   # "/categories/3/posts/9"
      Alkemist.Paths.for(paths, :index, query: %{"page" => 2}) # "/categories/3/posts?page=2"
  """

  alias Alkemist.Routes

  @enforce_keys [:conn, :controller]
  defstruct [:conn, :controller, route_params: []]

  @type t :: %__MODULE__{conn: Plug.Conn.t(), controller: module(), route_params: [term()]}

  @doc "Builds the paths struct for a controller."
  @spec new(Plug.Conn.t(), module(), [term()]) :: t()
  def new(conn, controller, route_params \\ []) do
    %__MODULE__{conn: conn, controller: controller, route_params: List.wrap(route_params)}
  end

  @doc """
  The path to `action`. A record (or id) is appended after the route params; `query:`
  becomes the query string; `controller:` targets another Alkemist controller (its own
  nesting is not applied).
  """
  @spec for(t(), atom(), struct() | term() | nil, keyword()) :: String.t()
  def for(paths, action, record \\ nil, opts \\ [])

  def for(%__MODULE__{} = paths, action, opts, []) when is_list(opts), do: __MODULE__.for(paths, action, nil, opts)

  def for(%__MODULE__{conn: conn, controller: controller, route_params: route_params}, action, record, opts) do
    {controller, route_params} =
      case Keyword.fetch(opts, :controller) do
        {:ok, other} -> {other, []}
        :error -> {controller, route_params}
      end

    params = if is_nil(record), do: route_params, else: route_params ++ [record]
    Routes.path(conn, controller, action, params, Keyword.get(opts, :query, %{}))
  end

  @doc "The path to `action` of the Alkemist controller serving `schema`, or `nil` when none is mounted."
  @spec for_schema(t(), module(), atom(), struct() | nil, keyword()) :: String.t() | nil
  def for_schema(%__MODULE__{conn: conn} = paths, schema, action, record \\ nil, opts \\ []) do
    case Routes.controller_for(conn, schema) do
      nil -> nil
      controller -> __MODULE__.for(paths, action, record, Keyword.put(opts, :controller, controller))
    end
  end
end
