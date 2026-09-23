defmodule Alkemist.Controller do
  @moduledoc """
  Macros that turn a plain Phoenix controller into a CRUD admin controller.

  ## Minimal example

  ```elixir
  defmodule MyAppWeb.Admin.PostController do
    use MyAppWeb, :controller

    # Set the Ecto schema BEFORE `use Alkemist.Controller`.
    @resource MyApp.Blog.Post
    use Alkemist.Controller, otp_app: :my_app

    menu "Posts", parent: "Blog"

    def index(conn, params), do: render_index(conn, params)
    def show(conn, %{"id" => id}), do: render_show(conn, id)
    def new(conn, _params), do: render_new(conn)
    def edit(conn, %{"id" => id}), do: render_edit(conn, id)
    def create(conn, %{"post" => params}), do: do_create(conn, params)
    def update(conn, %{"id" => id, "post" => params}), do: do_update(conn, id, params)
    def delete(conn, %{"id" => id}), do: do_delete(conn, id)
    def export(conn, params), do: csv(conn, params)
  end
  ```

  Mount it with `alkemist_resources "/posts", PostController` (see `Alkemist.Router`).
  Paths are derived from the router at runtime by `Alkemist.Routes`; no
  `Router.Helpers` are needed.

  ## Options

  Every macro accepts a keyword list. Any option can instead be provided as a function
  on the controller with the same name; explicit options win. The functions Alkemist
  looks for are the optional callbacks of this behaviour, for example:

  ```elixir
  @impl true
  def columns(_conn), do: [:id, :title, {"Author", fn post -> post.author.name end}]

  @impl true
  def scopes(_conn), do: [:all, {:published, [], fn q -> where(q, published: true) end}]

  @impl true
  def member_actions, do: [:show, :edit, :delete, :publish]
  ```

  Custom member or collection actions need their own route in the router, e.g.
  `get "/posts/:id/publish", PostController, :publish`.

  ## Authorization

  Before rendering, each macro asks the configured `Alkemist.Authorization` provider:
  `:index`, `:create` and `:export` are checked against the schema module, `:show`,
  `:update` and `:delete` against the loaded record. Denied requests go through
  `forbidden/2`.
  """

  alias Alkemist.{Assign, Authorization, Config, Routes, Utils}

  @type action :: atom() | {atom(), keyword()}
  @type scope ::
          atom()
          | {atom(), keyword()}
          | {atom(), keyword(), (Ecto.Queryable.t() -> Ecto.Queryable.t())}
  @type column ::
          atom()
          | {String.t(), (struct() -> term())}
          | {String.t(), map()}
          | {String.t(), (struct() -> term()), map()}
          | {atom(), map()}
  @typedoc "Filter definitions for the search form: `:field` or `{:field, %{type: :select, collection: [...]}}`."
  @type filter :: atom() | {atom(), map()}
  @type field ::
          atom() | {atom(), map()} | %{title: String.t(), fields: [atom() | {atom(), map()}]}
  @type panel :: {String.t(), keyword()}

  @callback columns(Plug.Conn.t()) :: [column()]
  @callback csv_columns(Plug.Conn.t()) :: [column()]
  @callback fields(Plug.Conn.t(), struct() | nil) :: [field()]
  @callback scopes(Plug.Conn.t()) :: [scope()]
  @callback filters(Plug.Conn.t()) :: [filter()]
  @callback rows(Plug.Conn.t(), struct()) :: [column()]
  @callback show_panels(Plug.Conn.t(), struct()) :: [panel()]
  @callback show_sidebars(Plug.Conn.t(), struct()) :: [panel()]
  @callback form_partial(Plug.Conn.t(), struct() | nil) :: tuple()
  @callback repo() :: module()
  @callback preload() :: keyword() | [atom()]
  @callback member_actions() :: [action()]
  @callback collection_actions() :: [action()]
  @callback batch_actions() :: [action()]
  @callback singular_name() :: String.t()
  @callback plural_name() :: String.t()
  @callback search_provider() :: module()
  @callback pagination_provider() :: module()
  @doc "The param key of the form (`:post` for `%{\"post\" => params}`); defaults to `Alkemist.Naming.resource_key/1`."
  @callback resource_key() :: atom()
  @doc "Overrides path building for this controller; see `Alkemist.Routes.path/5`."
  @callback path_for(Plug.Conn.t(), atom(), [term()], map()) :: String.t()

  @optional_callbacks columns: 1,
                      csv_columns: 1,
                      fields: 2,
                      scopes: 1,
                      filters: 1,
                      rows: 2,
                      show_panels: 2,
                      show_sidebars: 2,
                      form_partial: 2,
                      repo: 0,
                      preload: 0,
                      member_actions: 0,
                      collection_actions: 0,
                      batch_actions: 0,
                      singular_name: 0,
                      plural_name: 0,
                      search_provider: 0,
                      pagination_provider: 0,
                      resource_key: 0,
                      path_for: 4

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @otp_app Keyword.get(opts, :otp_app, :alkemist)
      @behaviour Alkemist.Controller
      import Alkemist.Assign
      import Alkemist.Controller
      import Ecto.Query

      Module.register_attribute(__MODULE__, :alkemist_menu, [])
      @alkemist_menu Alkemist.Menu.default_item(__MODULE__, @resource)
      @before_compile Alkemist.Controller
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    item = Module.get_attribute(env.module, :alkemist_menu)
    resource = Module.get_attribute(env.module, :resource)

    quote do
      @doc false
      def __alkemist_menu__, do: unquote(Macro.escape(item))

      @doc false
      def __alkemist_resource__, do: unquote(resource)
    end
  end

  @doc """
  Customises this controller's sidebar entry. Call it after `use Alkemist.Controller`.

      menu false                                   # no entry
      menu "Custom label"
      menu "Label", parent: "Dropdown title"        # grouped under a dropdown
      menu "Label", parent: "P", index: 2, parent_index: 1
      menu "Reports", to: "/admin/reports"          # link anywhere
      menu "Posts", icon: "hero-document-text"      # icon next to the label

  Items are discovered at runtime from the router, see `Alkemist.Menu`.
  """
  defmacro menu(label, opts \\ []) do
    quote do
      @alkemist_menu Alkemist.Menu.item(__MODULE__, @resource, unquote(label), unquote(opts))
    end
  end

  @doc """
  Renders the index table.

  ## Options

  * `repo`, `preload`, `query` (an `Ecto.Query` to start from)
  * `columns` (`t:column/0`), `scopes` (`t:scope/0`), `filters` (`t:filter/0`)
  * `member_actions`, `collection_actions`, `batch_actions` (`t:action/0`); a non-empty
    `batch_actions` adds a checkbox column and a batch menu
  * `description` shown under the page title
  * `sidebars` (`t:panel/0`) rendered as cards in a right-hand column
  * `search_provider`, `pagination_provider`, `scope_counts`
  * `route_params` for nested routes, `assigns` for extra template assigns

  ```elixir
  def index(conn, params) do
    render_index(conn, params,
      columns: [:id, :title, {"Category", fn p -> p.category.name end}],
      scopes: [:all, {:published, [default: true], fn q -> where(q, published: true) end}],
      filters: [:title, category_id: %{type: :select, collection: categories()}],
      preload: [:category]
    )
  end
  ```
  """
  defmacro render_index(conn, params, opts \\ []) do
    opts = get_module_opts(opts, :index, conn)

    quote do
      conn = unquote(conn)
      opts = unquote(opts) |> Alkemist.Controller.page_opts(__MODULE__, conn, @otp_app)

      if Alkemist.Controller.authorized?(conn, @resource, :index, @otp_app) do
        assigns =
          unquote(params)
          |> Assign.index_assigns(@resource, opts)
          |> Keyword.put(:has_export, function_exported?(__MODULE__, :export, 2))

        Alkemist.Controller.render_page(conn, :index, assigns, @otp_app)
      else
        Alkemist.Controller.forbidden(conn, @otp_app)
      end
    end
  end

  @doc """
  Renders the show page. `resource` is an id or a loaded record.

  Options: `preload`, `repo`, `rows` (same syntax as columns), `show_panels`
  (`[{"Heading", content: html}]` or `component:` entries; add `tab: "Name"` to put a
  panel on its own tab and `count:` for the tab's badge), `sidebars` (cards in the right
  column; also `show_sidebars/2` on the controller), `route_params`.
  """
  defmacro render_show(conn, resource, opts \\ []) do
    opts = get_module_opts(opts, :show, conn, resource)

    quote do
      conn = unquote(conn)
      opts = unquote(opts) |> Alkemist.Controller.page_opts(__MODULE__, conn, @otp_app)

      case opts[:resource] do
        nil ->
          Alkemist.Controller.not_found(conn, @otp_app)

        resource ->
          if Alkemist.Controller.authorized?(conn, resource, :show, @otp_app) do
            assigns = Assign.show_assigns(resource, opts)
            Alkemist.Controller.render_page(conn, :show, assigns, @otp_app)
          else
            Alkemist.Controller.forbidden(conn, @otp_app)
          end
      end
    end
  end

  @doc "Renders the new form; see `render_form/3`. Checks the `:create` permission."
  defmacro render_new(conn, opts \\ []) do
    opts = get_module_opts(opts, :new, conn)

    quote do
      conn = unquote(conn)
      opts = unquote(opts) |> Keyword.put_new(:otp_app, @otp_app)

      if Alkemist.Controller.authorized?(conn, @resource, :create, @otp_app) do
        render_form(conn, :new, opts)
      else
        Alkemist.Controller.forbidden(conn, @otp_app)
      end
    end
  end

  @doc "Renders the edit form; see `render_form/3`. Checks the `:update` permission on the record."
  defmacro render_edit(conn, resource, opts \\ []) do
    opts = get_module_opts(opts, :edit, conn, resource)

    quote do
      conn = unquote(conn)
      opts = unquote(opts) |> Keyword.put_new(:otp_app, @otp_app)

      case opts[:resource] do
        nil ->
          Alkemist.Controller.not_found(conn, @otp_app)

        resource ->
          if Alkemist.Controller.authorized?(conn, resource, :update, @otp_app) do
            render_form(conn, :edit, opts)
          else
            Alkemist.Controller.forbidden(conn, @otp_app)
          end
      end
    end
  end

  @doc """
  Renders the form for `:new` or `:edit`.

  Options: `preload`, `repo`, `changeset` (a changeset or the name of the changeset
  function, default `:changeset`), `fields` (`t:field/0`), `form_partial`, `route_params`.
  The permission (`:create` for `:new`, `:update` otherwise) is checked here too, so the
  macro is safe to call directly.
  """
  defmacro render_form(conn, action, opts \\ []) do
    quote do
      conn = unquote(conn)
      action = unquote(action)
      opts = unquote(opts) |> Alkemist.Controller.page_opts(__MODULE__, conn, @otp_app)
      subject = opts[:resource] || @resource

      if Alkemist.Controller.authorized?(conn, subject, Alkemist.Controller.form_permission(action), @otp_app) do
        assigns = Assign.form_assigns(@resource, opts)
        Alkemist.Controller.render_page(conn, action, assigns, @otp_app)
      else
        Alkemist.Controller.forbidden(conn, @otp_app)
      end
    end
  end

  @doc """
  Inserts a record from `params` and redirects to its show page.

  Options: `changeset` (function name, default `:changeset`), `repo`, `route_params`,
  `success_callback` (receives the new record and must return a conn), `error_callback`
  (receives the changeset and must return a conn).
  """
  defmacro do_create(conn, params, opts \\ []) do
    quote do
      conn = unquote(conn)

      opts =
        unquote(opts)
        |> Keyword.put_new(:otp_app, @otp_app)
        |> Keyword.put_new(:changeset, :changeset)

      route_params = List.wrap(opts[:route_params])

      if Alkemist.Controller.authorized?(conn, @resource, :create, @otp_app) do
        params = unquote(params)

        changeset =
          case opts[:changeset] do
            fun when is_atom(fun) -> apply(@resource, fun, [struct(@resource), params])
            changeset -> changeset
          end

        case Alkemist.Controller.repo(opts, @otp_app).insert(changeset) do
          {:ok, record} ->
            if opts[:success_callback] do
              opts[:success_callback].(record)
            else
              conn
              |> Phoenix.Controller.put_flash(
                :info,
                Utils.singular_name(@resource) <> " created successfully"
              )
              |> Phoenix.Controller.redirect(to: Routes.path(conn, __MODULE__, :show, route_params ++ [record]))
            end

          {:error, changeset} ->
            if opts[:error_callback] do
              opts[:error_callback].(changeset)
            else
              render_new(conn, changeset: changeset, route_params: route_params)
            end
        end
      else
        Alkemist.Controller.forbidden(conn, @otp_app)
      end
    end
  end

  @doc """
  Updates `resource` (an id or record) from `params` and redirects to its show page.
  Options as for `do_create/3`.
  """
  defmacro do_update(conn, resource, params, opts \\ []) do
    quote do
      conn = unquote(conn)

      opts =
        unquote(opts)
        |> Keyword.put_new(:otp_app, @otp_app)
        |> Keyword.put_new(:changeset, :changeset)

      route_params = List.wrap(opts[:route_params])
      resource = Alkemist.Controller.load_resource(unquote(resource), @resource, opts, @otp_app)

      cond do
        is_nil(resource) ->
          Alkemist.Controller.not_found(conn, @otp_app)

        not Alkemist.Controller.authorized?(conn, resource, :update, @otp_app) ->
          Alkemist.Controller.forbidden(conn, @otp_app)

        true ->
          params = unquote(params)

          changeset =
            case opts[:changeset] do
              fun when is_atom(fun) -> apply(@resource, fun, [resource, params])
              changeset -> changeset
            end

          case Alkemist.Controller.repo(opts, @otp_app).update(changeset) do
            {:ok, record} ->
              if opts[:success_callback] do
                opts[:success_callback].(record)
              else
                conn
                |> Phoenix.Controller.put_flash(
                  :info,
                  Utils.singular_name(@resource) <> " updated successfully"
                )
                |> Phoenix.Controller.redirect(to: Routes.path(conn, __MODULE__, :show, route_params ++ [record]))
              end

            {:error, changeset} ->
              if opts[:error_callback] do
                opts[:error_callback].(changeset)
              else
                render_edit(conn, resource, changeset: changeset, route_params: route_params)
              end
          end
      end
    end
  end

  @doc """
  Deletes `resource` (an id or record) and redirects to the index.

  Options: `repo`, `route_params`, `delete_func` (receives the record, returns
  `{:ok, record} | {:error, reason}`), `success_callback` (receives the deleted record),
  `error_callback` (receives the record and the error reason).
  """
  defmacro do_delete(conn, resource, opts \\ []) do
    quote do
      conn = unquote(conn)
      opts = unquote(opts) |> Keyword.put_new(:otp_app, @otp_app)
      route_params = List.wrap(opts[:route_params])
      resource = Alkemist.Controller.load_resource(unquote(resource), @resource, opts, @otp_app)

      cond do
        is_nil(resource) ->
          Alkemist.Controller.not_found(conn, @otp_app)

        not Alkemist.Controller.authorized?(conn, resource, :delete, @otp_app) ->
          Alkemist.Controller.forbidden(conn, @otp_app)

        true ->
          result =
            if opts[:delete_func],
              do: opts[:delete_func].(resource),
              else: Alkemist.Controller.repo(opts, @otp_app).delete(resource)

          index_path = Routes.path(conn, __MODULE__, :index, route_params)

          case result do
            {:ok, deleted} ->
              if opts[:success_callback] do
                opts[:success_callback].(deleted)
              else
                conn
                |> Phoenix.Controller.put_flash(
                  :info,
                  Utils.singular_name(@resource) <> " deleted successfully"
                )
                |> Phoenix.Controller.redirect(to: index_path)
              end

            {:error, reason} ->
              if opts[:error_callback] do
                opts[:error_callback].(resource, reason)
              else
                message =
                  if reason == :forbidden,
                    do: "You are not authorized to delete this resource",
                    else: "Oops, something went wrong"

                conn
                |> Phoenix.Controller.put_flash(:error, message)
                |> Phoenix.Controller.redirect(to: index_path)
              end
          end
      end
    end
  end

  @doc """
  Streams the current scope and filters as a CSV download (never paginated). Checks the
  `:export` permission. Columns come from `csv_columns/1`, then `columns/1`; a column's
  `%{export: fn record -> value end}` overrides the exported cell. Accepts the `csv:`
  config keys (`separator`, `bom`, `filename`, `max_rows`) as options; see
  `Alkemist.Export.CSV` and `render_index/3` for the rest.
  """
  defmacro csv(conn, params, opts \\ []) do
    opts = get_module_opts(opts, :export, conn)

    quote do
      conn = unquote(conn)
      opts = unquote(opts) |> Keyword.put_new(:otp_app, @otp_app)

      if Alkemist.Controller.authorized?(conn, @resource, :export, @otp_app) do
        %{query: query, columns: columns, preload: preload, repo: repo} =
          Assign.csv_query(unquote(params), @resource, opts)

        Alkemist.Export.CSV.send_stream(
          conn,
          query,
          columns,
          Keyword.merge(opts, repo: repo, preload: preload, schema: @resource)
        )
      else
        Alkemist.Controller.forbidden(conn, @otp_app)
      end
    end
  end

  ## Runtime helpers used by the macros

  @doc false
  def authorized?(conn, resource, action, otp_app) do
    Authorization.authorized?(Config.authorization_provider(otp_app), resource, conn, action)
  end

  @doc false
  def put_show_sidebars(opts) do
    case Keyword.fetch(opts, :show_sidebars) do
      {:ok, sidebars} -> Keyword.put_new(opts, :sidebars, sidebars)
      :error -> opts
    end
  end

  @doc false
  def repo(opts, otp_app), do: Keyword.get(opts, :repo) || Config.repo(otp_app)

  @doc false
  @spec form_permission(atom()) :: :create | :update
  def form_permission(:new), do: :create
  def form_permission(_edit), do: :update

  @doc false
  # Adds what Assign needs to build paths and pick the theme.
  def page_opts(opts, controller, conn, otp_app) do
    opts
    |> Keyword.put_new(:otp_app, otp_app)
    |> Keyword.put_new(:controller, controller)
    |> Keyword.put_new(:conn, conn)
    |> Keyword.put_new(:theme, nil)
  end

  @doc false
  # Every page renders through the component-based `Alkemist.ResourceHTML` inside the root
  # layout. Module-form put_view/put_root_layout replace the legacy defaults a plain
  # `use Phoenix.Controller` installs, which per-format options cannot override.
  def render_page(conn, template, assigns, otp_app) do
    conn
    |> Phoenix.Controller.put_root_layout(Config.get(:root_layout, otp_app))
    |> Phoenix.Controller.put_layout(false)
    |> Phoenix.Controller.put_view(Alkemist.ResourceHTML)
    |> Phoenix.Controller.render(template, Keyword.delete(assigns, :conn))
  end

  @doc """
  Handles a denied request according to `forbidden_redirect_to` in the config: a path
  (default `"/"`) or `{module, function}` receiving the conn to redirect to, or `:render`
  to answer 403 in place.
  """
  def forbidden(conn, otp_app) do
    case Config.forbidden_redirect_to(otp_app) do
      :render ->
        error_page(conn, :forbidden, otp_app)

      {module, function} ->
        Phoenix.Controller.redirect(conn, to: apply(module, function, [conn]))

      path when is_binary(path) ->
        conn
        |> Phoenix.Controller.put_flash(:error, "You are not authorized to access this page")
        |> Phoenix.Controller.redirect(to: path)
    end
  end

  @doc "Answers 404 with Alkemist's error page."
  def not_found(conn, otp_app \\ :alkemist), do: error_page(conn, :not_found, otp_app)

  defp error_page(conn, status, otp_app) do
    code = Plug.Conn.Status.code(status)

    conn
    |> Plug.Conn.put_status(code)
    |> Phoenix.Controller.put_root_layout(Config.get(:root_layout, otp_app))
    |> Phoenix.Controller.put_layout(false)
    |> Phoenix.Controller.put_view(Alkemist.ErrorHTML)
    |> Phoenix.Controller.render(:"#{code}", alkemist_app: otp_app)
  end

  @doc """
  Loads a record by primary key, casting the id with the key's `Ecto.Type`, and applies
  `opts[:preload]`. Returns `nil` for an unknown or malformed id. Records are passed
  through (and preloaded).
  """
  @spec load_resource(term(), module(), keyword(), atom()) :: struct() | nil
  def load_resource(nil, _schema, _opts, _otp_app), do: nil

  def load_resource(%{__struct__: _} = record, _schema, opts, otp_app),
    do: maybe_preload(record, opts, otp_app)

  def load_resource(id, schema, opts, otp_app) do
    {pk, type} = Alkemist.Schema.primary_key!(schema)

    case cast_id(type, id) do
      {:ok, value} ->
        schema |> repo(opts, otp_app).get_by([{pk, value}]) |> maybe_preload(opts, otp_app)

      :error ->
        nil
    end
  end

  defp cast_id(:binary_id, id) when is_binary(id), do: Ecto.UUID.cast(id)
  defp cast_id(type, id), do: Ecto.Type.cast(type, id)

  defp maybe_preload(nil, _opts, _otp_app), do: nil

  defp maybe_preload(record, opts, otp_app) do
    case opts[:preload] do
      nil -> record
      preload -> repo(opts, otp_app).preload(record, preload)
    end
  end

  @doc false
  # For each key, keeps an explicit option or calls the controller function of the same
  # name. `{key, assign, args}` stores the result under a different key.
  def opts_or_function(opts, module, keys) do
    Enum.reduce(keys, opts, fn key, opts ->
      {key, assign, args} =
        case key do
          {key, assign, args} -> {key, assign, args}
          {key, args} -> {key, key, args}
          key -> {key, key, []}
        end

      cond do
        Keyword.has_key?(opts, assign) ->
          opts

        function_exported?(module, key, length(args)) ->
          Keyword.put(opts, assign, apply(module, key, args))

        true ->
          opts
      end
    end)
  end

  defp get_module_opts(opts, :global, conn) do
    quote do
      opts = unquote(opts)
      conn = unquote(conn)

      Alkemist.Controller.opts_or_function(opts, __MODULE__, [
        :repo,
        :preload,
        :collection_actions,
        :member_actions,
        :batch_actions,
        :singular_name,
        :plural_name,
        {:resource_key, :struct, []}
      ])
    end
  end

  defp get_module_opts(opts, :index, conn) do
    opts = get_module_opts(opts, :global, conn)

    quote do
      opts = unquote(opts)
      conn = unquote(conn)

      Alkemist.Controller.opts_or_function(opts, __MODULE__,
        columns: [conn],
        scopes: [conn],
        filters: [conn],
        search_provider: [],
        pagination_provider: []
      )
    end
  end

  defp get_module_opts(opts, :new, conn) do
    opts = get_module_opts(opts, :global, conn)

    quote do
      opts = unquote(opts)
      conn = unquote(conn)

      opts =
        opts
        |> Alkemist.Controller.opts_or_function(__MODULE__,
          form_partial: [conn, nil],
          fields: [conn, nil]
        )
        |> Keyword.put_new(:changeset, :changeset)

      case opts[:changeset] do
        fun when is_atom(fun) ->
          Keyword.put(opts, :changeset, apply(@resource, fun, [struct(@resource), %{}]))

        _ ->
          opts
      end
    end
  end

  defp get_module_opts(opts, :export, conn) do
    opts = get_module_opts(opts, :global, conn)

    quote do
      opts = unquote(opts)
      conn = unquote(conn)

      Alkemist.Controller.opts_or_function(opts, __MODULE__, [
        {:csv_columns, :columns, [conn]},
        {:columns, [conn]},
        {:scopes, [conn]},
        {:search_provider, []}
      ])
    end
  end

  defp get_module_opts(opts, :show, conn, resource) do
    opts = get_module_opts(opts, :global, conn)

    quote do
      opts = unquote(opts)
      conn = unquote(conn)
      resource = Alkemist.Controller.load_resource(unquote(resource), @resource, opts, @otp_app)

      # Record callbacks only run for a record that exists; a missing one renders 404.
      if is_nil(resource) do
        Keyword.put(opts, :resource, nil)
      else
        opts
        |> Alkemist.Controller.opts_or_function(__MODULE__,
          show_panels: [conn, resource],
          rows: [conn, resource],
          show_sidebars: [conn, resource]
        )
        |> Alkemist.Controller.put_show_sidebars()
        |> Keyword.put(:resource, resource)
      end
    end
  end

  defp get_module_opts(opts, :edit, conn, resource) do
    opts = get_module_opts(opts, :global, conn)

    quote do
      opts = unquote(opts)
      conn = unquote(conn)
      resource = Alkemist.Controller.load_resource(unquote(resource), @resource, opts, @otp_app)

      if is_nil(resource) do
        Keyword.put(opts, :resource, nil)
      else
        opts =
          opts
          |> Alkemist.Controller.opts_or_function(__MODULE__,
            form_partial: [conn, resource],
            fields: [conn, resource]
          )
          |> Keyword.put_new(:changeset, :changeset)
          |> Keyword.put(:resource, resource)

        case opts[:changeset] do
          fun when is_atom(fun) ->
            Keyword.put(opts, :changeset, apply(@resource, fun, [resource, %{}]))

          _ ->
            opts
        end
      end
    end
  end
end
