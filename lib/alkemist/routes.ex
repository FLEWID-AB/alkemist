defmodule Alkemist.RouteError do
  @moduledoc "Raised when no route exists in the host router for a controller action Alkemist needs to link to."
  defexception [:controller, :action, :router]

  @impl true
  def message(%{controller: controller, action: action, router: router}) do
    "no route for #{inspect(controller)} :#{action} in #{inspect(router)}. " <>
      "Add it with `alkemist_resources/2` or define `path_for/4` on the controller."
  end
end

defmodule Alkemist.Routes do
  @moduledoc """
  Builds paths to Alkemist controller actions **from the host router itself**, so no
  `Router.Helpers` module or `route_prefix` configuration is needed.

  The router that dispatched the current request is read from `conn.private`, its
  compiled route table (`Phoenix.Router.routes/1`) is searched for the
  `{controller, action}` pair, and the path template is filled in with `route_params`
  followed by the record. Templates are memoised in `:persistent_term`.

  A controller can take over path building entirely by defining
  `path_for(conn, action, route_params, query)`.
  """

  @type route_params :: [term()]

  @doc """
  The path to `action` of `controller`.

  `route_params` fills the template's parameters **in order**, exactly like the
  arguments to a Phoenix path helper: for `/categories/:category_id/posts/:id` pass
  `[category_id, post]`. Structs are converted with `Phoenix.Param`.
  """
  @spec path(Plug.Conn.t(), module(), atom(), route_params(), map() | keyword()) :: String.t()
  def path(conn, controller, action, route_params \\ [], query \\ %{}) do
    if function_exported?(controller, :path_for, 4) do
      controller.path_for(conn, action, route_params, query)
    else
      router = router!(conn)
      template = template(router, controller, action, conn.request_path)
      build(conn, template, route_params, query)
    end
  end

  @doc """
  Finds the Alkemist controller mounted in the router for a schema, i.e. the one whose
  `__alkemist_resource__/0` returns the schema. Returns `nil` when there is none.
  """
  @spec controller_for(module() | Plug.Conn.t(), module()) :: module() | nil
  def controller_for(%Plug.Conn{} = conn, schema), do: controller_for(router!(conn), schema)

  def controller_for(router, schema) when is_atom(router) do
    lookup(router, {:controller_for, schema}, fn ->
      router
      |> Phoenix.Router.routes()
      |> Enum.map(& &1.plug)
      |> Enum.uniq()
      |> Enum.find(fn plug ->
        Code.ensure_loaded?(plug) and function_exported?(plug, :__alkemist_resource__, 0) and
          plug.__alkemist_resource__() == schema
      end)
    end)
  end

  @doc "True when the router has a route for `{controller, action}`."
  @spec route?(module() | Plug.Conn.t(), module(), atom()) :: boolean()
  def route?(%Plug.Conn{} = conn, controller, action),
    do: route?(router!(conn), controller, action)

  def route?(router, controller, action) do
    Enum.any?(Phoenix.Router.routes(router), &(&1.plug == controller and &1.plug_opts == action))
  end

  @doc "Forgets memoised templates, e.g. after code reloading in tests."
  @spec reset(module()) :: :ok
  def reset(router) do
    for {{__MODULE__, ^router, _} = key, _} <- :persistent_term.get(),
        do: :persistent_term.erase(key)

    :ok
  end

  @doc false
  def router!(%Plug.Conn{private: %{phoenix_router: router}}), do: router

  def router!(%Plug.Conn{}) do
    raise ArgumentError,
          "conn has no :phoenix_router; Alkemist paths can only be built inside a request dispatched by a Phoenix router"
  end

  # The path template for {controller, action}. When the controller is mounted more than
  # once, the template sharing the longest prefix with the current request path wins.
  defp template(router, controller, action, request_path) do
    templates =
      lookup(router, {:templates, controller, action}, fn ->
        router
        |> Phoenix.Router.routes()
        |> Enum.filter(&(&1.plug == controller and &1.plug_opts == action))
        |> Enum.map(& &1.path)
        |> Enum.uniq()
      end)

    case templates do
      [] -> raise Alkemist.RouteError, controller: controller, action: action, router: router
      [only] -> only
      many -> Enum.max_by(many, &prefix_overlap(&1, request_path))
    end
  end

  defp prefix_overlap(template, request_path) do
    template
    |> String.split("/", trim: true)
    |> Enum.zip(String.split(request_path || "", "/", trim: true))
    |> Enum.take_while(fn {t, r} -> String.starts_with?(t, ":") or t == r end)
    |> length()
  end

  defp build(conn, template, route_params, query) do
    {segments, rest} =
      template
      |> String.split("/", trim: true)
      |> Enum.map_reduce(List.wrap(route_params), fn
        ":" <> _param, [value | rest] -> {to_param(value), rest}
        ":" <> param, [] -> raise ArgumentError, "missing value for :#{param} in #{template}"
        "*" <> _glob, values -> {Enum.map_join(values, "/", &to_param/1), []}
        segment, acc -> {segment, acc}
      end)

    if rest != [] do
      raise ArgumentError, "too many route params #{inspect(route_params)} for #{template}"
    end

    path = "/" <> Enum.join(segments, "/")
    script_name(conn) <> path <> query_string(query)
  end

  defp script_name(%Plug.Conn{script_name: []}), do: ""
  defp script_name(%Plug.Conn{script_name: parts}), do: "/" <> Enum.join(parts, "/")

  defp query_string(query) when query in [nil, %{}, []], do: ""
  defp query_string(query), do: "?" <> Plug.Conn.Query.encode(query)

  defp to_param(value),
    do: value |> Phoenix.Param.to_param() |> URI.encode(&URI.char_unreserved?/1)

  defp lookup(router, key, fun) do
    term_key = {__MODULE__, router, key}

    case :persistent_term.get(term_key, :__miss__) do
      :__miss__ ->
        value = fun.()
        :persistent_term.put(term_key, value)
        value

      value ->
        value
    end
  end
end
