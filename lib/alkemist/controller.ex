defmodule Alkemist.Controller do
  @moduledoc """
  Provides helper macros to use inside of CRUD controllers.

  ## Example with minimal configuration:

  ```elixir
  defmodule MyAppWeb.MyController do
    use MyAppWeb, :controller

    # Specify the Ecto Schema as resource - it is important to call this above
    # use Alkemist.Controller!
    @resource MyApp.MySchema
    use Alkemist.Controller

    def index(conn, params) do
      render_index(conn, params)
    end

    def show(conn, %{"id" => id}) do
      render_show(conn, id)
    end

    def edit(conn, %{"id" => id}) do
      render_edit(conn, id)
    end

    def new(conn, _params) do
      render_new(conn)
    end

    def create(conn, %{"my_schema" => params}) do
      do_create(conn, params)
    end

    def update(conn, %{"id" => id, "my_schema" => params}) do
      do_update(conn, id, params)
    end

    def delete(conn, %{"id" => id}) do
      do_delete(conn, id)
    end

    def export(conn, params) do
      csv(conn, params)
    end
  end
  ```

  ## The following methods can be implemented to set configuration on a global level:

  * `repo` - needs to return a valid `Ecto.Repo`
  * `preload` - return a keyword list of resources to preload in all controller actions
  * `collection_actions` - a list of actions to list in the collection action menu.
    They need to be implemented in your controller and a custom route to that function needs to be
    added to your router.
  * `member_actions` - a list of actions that is available for each individual resource.
    They need to be implemented in your controller and a custom router needs to be added to your router

  ## Example for a custom member action:

  In your router.ex:

  ```
  scope "/admin", MyApp, do
    ...
    get "/my_resource/:id/my_func", MyController, :my_func
    alkemist_resources("/my_resource", MyController)
  end
  ```

  In your controller:

  ```elixir
  def member_actions do
    [:show, :edit, :delete, :my_func]
  end

  def my_func(conn, %{"id" => id}) do
    # do something with the resource
    conn
    |> put_layout({Alkemist.LayoutView, "app.html"})
    |> render("my_template.html", resource: my_resource)
  end
  ```
  """
  alias Alkemist.{Utils, Assign.Index, Assign.Show, Assigns.Form}

  @callback columns(Plug.Conn.t()) :: [column()]
  @callback csv_columns(Plug.Conn.t()) :: [column()]
  @callback fields(Plug.Conn.t(), struct() | nil) :: [field() | map()]
  @callback scopes(Plug.Conn.t()) :: [scope()]
  @callback filters(Plug.Conn.t()) :: keyword()
  @callback repo() :: module()
  @callback preload() :: keyword()
  @callback rows(Plug.Conn.t(), struct() | nil) :: list()
  @callback form_partial(Plug.Conn.t(), struct() | nil) :: tuple()
  @callback batch_actions() :: keyword()
  @callback singular_name() :: String.t()
  @callback plural_name() :: String.t()

  @optional_callbacks [
    columns: 1,
    csv_columns: 1,
    fields: 2,
    scopes: 1,
    filters: 1,
    repo: 0,
    preload: 0,
    rows: 2,
    form_partial: 2,
    batch_actions: 0,
    singular_name: 0,
    plural_name: 0
  ]

  # Type definitions
  @type scope :: {atom(), keyword(), (%{} -> Ecto.Query.t())}
  @type column :: atom() | {String.t(), (%{} -> any())}
  @typedoc """
  Used to create custom filters in the filter form. Type can be in `[:string, :boolean, :select, :date]`,
  default is `:string`. If the type is `:select`, a collection to build the select must be passed (see `Phoenix.HTMl.Form.select/4`)
  """
  @type filter :: atom() | keyword()
  @type field :: atom() | {atom(), map()} | %{title: String.t(), fields: [{atom(), map()}]}


  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @otp_app Keyword.get(opts, :otp_app, :alkemist)
      import Alkemist.Assign
      import Alkemist.Controller
      @behaviour Alkemist.Controller
      import Ecto.Query
    end
  end

  @doc """
  Renders the default index view table.

  ## Params:

  * conn - the conn from the controller action
  * params - the params that are passed to the controller action
  * opts - a `t:Keyword.t/0` with options

  ## Options:

  * repo - use a custom `Ecto.Repo`
  * member_actions - customize the actions that will display for each resource
  * collection_actions - customize the global actions that are available for a collection of resources (e. g. `new`)
  * batch_actions - add custom batch actions to be performed on a number of selected resources.
    When set, a `selectable_column` will be added to the index table and a batch menu will display above the table.
  * columns - List of `t:column/0` customize the columns that will display in the index table
  * scopes - List of `t:scope/0` to define custom filter scopes
  * filters - List of `t:filter/0` to define filters for the search form
  * preload - resources to preload along with each resource (see `Ecto.Query`)
  * search_provider - define a custom library for building the search query


  ## Example with options:

  ```elixir
  def index(conn, params) do
    opts = [
      # Columns can either be an atom, or a `tuple` with a label and a custom modifier function
      columns: [
        :id,
        :title,
        :body,
        {"Author", fn i -> i.author.name end}
        ],
      batch_actions: [:delete_batch],
      member_actions: [:show, :edit, :my_custom_action],
      scopes: [
        {:published, [], fn(q) -> where(q, [p], p.published == true) end}
      ],
      preload: [:author]
    ]
    render_index(conn, params, opts)
  end
  ```

  ## Example with custom functions:

  ```elixir
  def index(conn, params) do
    render_index(conn, params)
  end

  def my_custom_action(conn, %{"id" => id}) do
    ...
  end

  def delete_all(conn, %{"batch_ids" => ids}) do
    # implement custom batch action
  end

  def columns do
    [
      :id,
      :title,
      :body,
      {"Author", fn i -> i.author.name end}
    ]
  end

  def scopes do
    [published: [], fn i -> i.published == true end]
  end

  def preload do
    [:author]
  end

  def member_actions do
    [:show, :edit, :my_custom_action]
  end

  def batch_actions do
    [:delete_batch]
  end
  ```
  """
  defmacro render_index(conn, params, opts \\ []) do
    opts = get_module_opts(opts, :index, conn)
    quote do
      conn = unquote(conn)
      if Alkemist.Config.authorization_provider(@otp_app).authorize_action(@resource, conn, :index) ==
           true do
        opts = unquote(opts) |> Keyword.put_new(:otp_app, @otp_app)
        assigns = Index.assigns(@resource, opts, unquote(params))

        assigns =
          if Keyword.has_key?(__MODULE__.__info__(:functions), :export) do
            Keyword.put(assigns, :has_export, true)
          else
            assigns
          end

        conn
        |> Phoenix.Controller.put_layout(Alkemist.Config.layout(@otp_app))
        |> Phoenix.Controller.put_view(AlkemistView)
        |> Phoenix.Controller.render("index.html", assigns)
      else
        Alkemist.Controller.forbidden(conn, @otp_app)
      end
    end
  end

  @doc """
  Renders the default show page.

  ## Options:

  * `preload` - Resources to preload. See `Ecto.Query`
  * `repo` - Define a custom repo to execute the query
  * `rows` - The values to display. Same syntax as `t:column/0`
  * `show_panels` - define custom panels that are shown underneath the resource table. Each panel consists of a tuple in the form
  `{"Panel Heading", content: my_html_content}

  Each of the above options can also be specified as controller functions, whereas rows and show_panels take to arguments `conn` and `resource`.
  The `resource` is the current resource (e. g. a specific user)

  ## Example with options:

  ```elixir
  def show(conn, %{"id" => id}) do
    post = Repo.get(Post, id) |> Repo.preload(:author)
    opts = [
      rows: [
        :id,
        :title,
        :body,
        {"Author", fn p ->
          unless p.author != nil do
            p.author.name
          end
        end}
      ],
      show_panels: [
        {"Author", content: Phoenix.View.render(
               MyApp.PostView,
               "author.html",
               author: post.author
             )}}
      ]
    ]
    render_show(conn, post, opts)
  ```

  ## Example with custom functions:

  ```elixir
  def show(conn, %{"id" => id}) do
    render_show(conn, id, preload: [:author])
  end

  def show_panels(_conn, post) do
    if post.author do
      [{
        "Author",
        content: Phoenix.View.render(
               MyApp.PostView,
               "author.html",
               author: post.author
             )
      }]
    else
      []
    end
  end

  def rows(_conn, post) do
    [:id, :title, :body]
  end
  ```
  """
  defmacro render_show(conn, resource, opts \\ []) do
    opts = get_module_opts(opts, :show, conn, resource)

    quote do
      conn = unquote(conn)
      opts = unquote(opts) |> Keyword.put_new(:otp_app, @otp_app)
      resource = opts[:resource]

      if resource == nil do
        Alkemist.Controller.not_found(conn)
      else
        if Alkemist.Config.authorization_provider(@otp_app).authorize_action(resource, conn, :show) do
          assigns = Show.assigns(resource, opts)

          conn
          |> Phoenix.Controller.put_layout(Alkemist.Config.layout(@otp_app))
          |> Phoenix.Controller.put_view(AlkemistView)
          |> Phoenix.Controller.render("show.html", assigns)
        else
          Alkemist.Controller.forbidden(conn, @otp_app)
        end
      end
    end
  end

  @doc """
  Renders the "new" action
  see `Alkemist.Controller.render_form/3`
  """
  defmacro render_new(conn, opts \\ []) do
    opts = get_module_opts(opts, :new, conn)

    quote do
      conn = unquote(conn)
      opts = unquote(opts)

      if Alkemist.Config.authorization_provider(@otp_app).authorize_action(@resource, conn, :create) do
        render_form(conn, :new, opts)
      else
        Alkemist.Controller.forbidden(conn, @otp_app)
      end
    end
  end

  @doc """
  Renders the "edit action"
  See `Alkemist.Controller.render_form/3`
  """
  defmacro render_edit(conn, resource, opts \\ []) do
    opts = get_module_opts(opts, :edit, conn, resource)

    quote do
      conn = unquote(conn)
      opts = unquote(opts)
      resource = opts[:resource]

      if resource == nil do
        Alkemist.Controller.not_found(conn)
      else
        if Alkemist.Config.authorization_provider(@otp_app).authorize_action(resource, conn, :update) do
          render_form(conn, :edit, opts)
        else
          Alkemist.Controller.forbidden(conn, @otp_app)
        end
      end
    end
  end

  @doc """
  Renders the form for edit and create actions.

  ## Options

  * `preload` - Resources to preload. See `Ecto.Query`
  * `repo` - Define a custom repo to execute the query
  * `form_partial` - a tuple in the format `{MyViewModule, "template.html"}` or `{MyViewModule, "template.html", assigns}`
  * `fields` - a list of either atoms representing the resource fields, maps with field groups or a keyword list in the format `[field_name: %{type: :type, other opts...}]`
  * `changeset` - use a custom changeset
  * `success_callback` - use a custom callback function that takes the newly updated/created resource as an argument
  * `error_callback` - use a custom callback function on error, takes changeset as argument

  ## Examples:

  ```elixir
  def edit(conn, %{"id" => id}) do
    opts = [
      preload: [:my_relationship]
      form_partial: {MyView, "edit.html"},
      changeset: :my_changeset,
      error_callback: fn(changeset) -> ... end
    ]
    render_edit(conn, id, opts)
  end
  ```
  `fields` and `form_partial` also can be defined as custom methods in the controller.

  ## Example with methods:

  ```elixir
  def edit(conn, %{"id" => id}) do
    render_edit(conn, id)
  end

  # resource will be nil on create
  def fields(_conn, _resource) do
    [
      :title,
      :body
    ]

    # or with custom types:
    # [title: %{type: :string, placeholder: "Enter title"}, body: %{type: :text}]

    # or use some custom form groups
    # [
    #   %{title: "My Model details", fields: [:title, :body]},
    #   %{title: "Next panel header", fields: [:category]}
    # ]
  end
  ```
  """
  defmacro render_form(conn, action, opts \\ []) do
    quote do
      opts = unquote(opts) |> Keyword.put_new(:otp_app, @otp_app)
      action = unquote(action)

      assigns = Form.assigns(@resource, opts)
      conn = unquote(conn)

      conn
      |> Phoenix.Controller.put_layout(Alkemist.Config.layout(@otp_app))
      |> Phoenix.Controller.put_view(AlkemistView)
      |> Phoenix.Controller.render("#{action}.html", assigns)
    end
  end

  @doc """
  Creates a new resource
  TODO: document opts
  """
  defmacro do_create(conn, params, opts \\ []) do
    route_params = route_params(opts)
    quote do
      conn = unquote(conn)
      route_params = unquote(route_params)

      if Alkemist.Config.authorization_provider(@otp_app).authorize_action(@resource, conn, :create) do
        opts =
          unquote(opts)
          |> Keyword.put_new(:changeset, :changeset)
          |> Keyword.put_new(:otp_app, @otp_app)

        opts =
          if is_atom(opts[:changeset]) do
            params = unquote(params)
            changeset = apply(@resource, opts[:changeset], [@resource.__struct__, params])
            Keyword.put(opts, :changeset, changeset)
          else
            opts
          end

        repo = Keyword.get(opts, :repo, Alkemist.Config.repo(@otp_app))

        case repo.insert(opts[:changeset]) do
          {:ok, new_resource} ->
            if opts[:success_callback] do
              opts[:success_callback].(new_resource)
            else
              path = String.to_atom("#{Utils.default_resource_helper(@resource)}")
              params = [conn, :show] ++ route_params ++ [new_resource]
              conn
              |> Phoenix.Controller.put_flash(
                :info,
                Utils.singular_name(@resource) <> " created successfully"
              )
              |> Phoenix.Controller.redirect(
                to: apply(Alkemist.Config.router_helpers(@otp_app), path, params)
              )
            end

          {:error, changeset} ->
            if opts[:error_callback] do
              opts[:error_callback].(changeset)
            else
              opts = [changeset: changeset, route_params: route_params]
              render_new(conn, opts)
            end
        end
      else
        Alkemist.Controller.forbidden(conn, @otp_app)
      end
    end
  end

  @doc """
  Performs an update to the resource

  ## Options:

  * `changeset` - use a custom changeset.
    Example: `changeset: :my_update_changeset`
  * `success_callback` - custom function that will be performed on update success. Accepts the new resource as argument
  * `error_callback` - custom function that will be performed on failure. Takes the changeset as argument.

  ## Examples:

  ```elixir
  def update(conn, %{"id" => id, "resource" => resource_params}) do
    do_update(conn, id, resource_params, changeset: :my_update_changeset)
  end
  ```

  Or use a custom success or error function:

  ```elixir
  def update(conn, %{"id" => id, "resource" => resource_params}) do
    opts = [
      changeset: :my_udpate_changeset
      success_callback: fn my_resource ->
        conn
        |> put_flash(:info, "Resource was successfully updated")
        |> redirect(to: my_resource_path(conn, :index))
      end
    ]
    do_update(conn, id, resource_params, opts)
  end
  ```
  """
  defmacro do_update(conn, resource, params, opts \\ []) do
    route_params = route_params(opts)
    quote do
      conn = unquote(conn)
      opts = unquote(opts) |> Keyword.put_new(:otp_app, @otp_app)
      resource = unquote(resource) |> Alkemist.Controller.load_resource(@resource, opts, @otp_app)
      route_params = unquote(route_params)

      if resource == nil do
        Alkemist.Controller.not_found(conn)
      else
        if Alkemist.Config.authorization_provider(@otp_app).authorize_action(resource, conn, :update) do
          params = unquote(params)

          opts =
            opts
            |> Keyword.put_new(:changeset, :changeset)

          opts =
            if is_atom(opts[:changeset]) do
              params = unquote(params)
              changeset = apply(@resource, opts[:changeset], [resource, params])
              Keyword.put(opts, :changeset, changeset)
            else
              opts
            end

          repo = Keyword.get(opts, :repo, Alkemist.Config.repo(@otp_app))

          case repo.update(opts[:changeset]) do
            {:ok, new_resource} ->
              if opts[:success_callback] do
                opts[:success_callback].(new_resource)
              else
                path = String.to_atom("#{Utils.default_resource_helper(@resource)}")
                route_params = [conn, :show] ++ route_params ++ [new_resource]
                conn
                |> Phoenix.Controller.put_flash(
                  :info,
                  Utils.singular_name(@resource) <> " updated successfully"
                )
                |> Phoenix.Controller.redirect(
                  to: apply(Alkemist.Config.router_helpers(@otp_app), path, route_params)
                )
              end

            {:error, changeset} ->
              if opts[:error_callback] do
                opts[:error_callback].(changeset)
              else
                opts = [changeset: changeset, route_params: route_params]
                render_edit(conn, resource, opts)
              end
          end
        else
          Alkemist.Controller.forbidden(conn, @otp_app)
        end
      end
    end
  end

  @doc """
  Performs a delete of the current resource. When successful, it will redirect to index.

  ## Options:

  * `delete_func` - use a custom method for deletion. Takes the resource as argument.
  * `success_callback` - custom function on success. Takes the deleted resource as argument
  * `error_callback` - custom function on error. Takes the resource as argument

  ## Examples:

  ```elixir
  def delete(conn, %{"id" => id}) do
    opts = [
      delete_func: fn r ->
        MyApp.MyService.deactivate(r)
      end,
      error_callback: fn r ->
        my_custom_error_function(conn, r)
      end
    ]
    do_delete(conn, id, opts)
  end
  ```
  """
  defmacro do_delete(conn, resource, opts \\ []) do
    route_params = route_params(opts)
    quote do
      conn = unquote(conn)
      opts = unquote(opts) |> Keyword.put_new(:otp_app, @otp_app)
      resource = unquote(resource) |> Alkemist.Controller.load_resource(@resource, opts, @otp_app)
      route_params = unquote(route_params)

      if resource == nil do
        Alkemist.Controller.not_found(conn)
      else
        if Alkemist.Config.authorization_provider(@otp_app).authorize_action(resource, conn, :delete) do
          res =
            if opts[:delete_func] do
              opts[:delete_func].(resource)
            else
              repo = Keyword.get(opts, :repo, Alkemist.Config.repo(@otp_app))
              repo.delete(resource)
            end

          case res do
            {:ok, deleted} ->
              if opts[:success_callback] do
                opts[:success_callback].(deleted)
              else
                path = String.to_atom("#{Utils.default_resource_helper(@resource)}")
                route_params = [conn, :index] ++ route_params

                conn
                |> Phoenix.Controller.put_flash(
                  :info,
                  Utils.singular_name(@resource) <> " deleted successfully"
                )
                |> Phoenix.Controller.redirect(
                  to: apply(Alkemist.Config.router_helpers(@otp_app), path, route_params)
                )
              end

            {:error, message} ->
              if opts[:error_callback] do
                opts[:error_callback].(message)
              else
                path = String.to_atom("#{Utils.default_resource_helper(@resource)}")
                route_params = [conn, :index] ++ route_params
                message =
                  if message == :forbidden do
                    "You are not authorized to delete this resource"
                  else
                    "Oops, something went wrong"
                  end

                conn
                |> Phoenix.Controller.put_layout(Alkemist.Config.layout(@otp_app))
                |> Phoenix.Controller.put_flash(:error, message)
                |> Phoenix.Controller.redirect(
                  to: apply(Alkemist.Config.router_helpers(@otp_app), path, route_params)
                )
              end
          end
        else
          Alkemist.Controller.forbidden(conn, @otp_app)
        end
      end
    end
  end

  @doc """
  Creates a csv export of all entries that match the current scope and filter.
  An export does not paginate.

  For available_options see `Alkemist.Controller.render_index/2`
  """
  defmacro csv(conn, params, opts \\ []) do
    opts = get_module_opts(opts, :export, conn)

    quote do
      conn = unquote(conn)
      opts = unquote(opts) |> Keyword.put_new(:otp_app, @otp_app)
      params = unquote(params)

      assigns = Alkemist.Assign.Export.assigns(@resource, opts, params)
      csv = Alkemist.Export.CSV.create_csv(assigns[:columns], assigns[:entries])

      conn
      |> Plug.Conn.put_resp_content_type("text/csv")
      |> Plug.Conn.put_resp_header("content-disposition", "attachment; filename=\"export.csv\"")
      |> Plug.Conn.send_resp(200, csv)
    end
  end

  # TODO: see if we can make the methods below private somehow
  def add_opt(opts, controller, key, atts \\ []) do
    cond do
      Keyword.has_key?(opts, key) ->
        opts

      Keyword.has_key?(controller.__info__(:functions), key) ->
        Keyword.put(opts, key, apply(controller, key, atts))

      true ->
        opts
    end
  end

  def forbidden(conn, application) do
    conn
    |> Phoenix.Controller.put_layout(Alkemist.Config.layout(application))
    |> Phoenix.Controller.put_flash(:error, "You are not authorized to access this page")
    |> Phoenix.Controller.redirect(
      to: Alkemist.Config.router_helpers(application).page_path(conn, :dashboard)
    )
  end

  def not_found(conn) do
    conn
    |> Plug.Conn.put_status(:not_found)
    |> Phoenix.Controller.put_view(Alkemist.ErrorView)
    |> Phoenix.Controller.render("404.html")
  end

  @doc """
  Loads the resource from the repo and adds any preloads
  """
  def load_resource(resource, mod, opts, application) when is_bitstring(resource),
    do: load_resource(String.to_integer(resource), mod, opts, application)

  def load_resource(resource, mod, opts, application) when is_integer(resource) do
    repo = Keyword.get(opts, :repo, Alkemist.Config.repo(application))
    load_resource(repo.get(mod, resource), mod, opts, application)
  end

  def load_resource(resource, _mod, opts, application) do
    if opts[:preload] do
      repo = Keyword.get(opts, :repo, Alkemist.Config.repo(application))
      resource |> repo.preload(opts[:preload])
    else
      resource
    end
  end

  def opts_or_function(opts, mod, keys) do
    Enum.reduce(keys, opts, fn key, opts ->
      {key, assign, params} =
        case key do
          {key, assign, params} -> {key, assign, params}
          {key, params} -> {key, key, params}
          key -> {key, key, []}
        end

      cond do
        Keyword.has_key?(opts, key) ->
          opts

        Keyword.has_key?(mod.__info__(:functions), key) ->
          Keyword.put(opts, assign, apply(mod, key, params))

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
        :plural_name
      ])
    end
  end

  defp get_module_opts(opts, :index, conn) do
    opts = get_module_opts(opts, :global, conn)

    quote do
      opts = unquote(opts)
      conn = unquote(conn)

      Alkemist.Controller.opts_or_function(
        opts,
        __MODULE__,
        columns: [conn],
        scopes: [conn],
        filters: [conn],
        search_provider: []
      )
    end
  end

  defp get_module_opts(opts, :new, conn) do
    opts = get_module_opts(opts, :global, conn)

    quote do
      opts = unquote(opts)
      conn = unquote(conn)

      opts =
        Alkemist.Controller.opts_or_function(
          opts,
          __MODULE__,
          form_partial: [conn, nil],
          fields: [conn, nil]
        )
        |> Keyword.put_new(:changeset, :changeset)

      if is_atom(opts[:changeset]) do
        changeset = apply(@resource, opts[:changeset], [@resource.__struct__, %{}])
        Keyword.put(opts, :changeset, changeset)
      else
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
        {:columns, [conn]}
      ])
    end
  end

  defp get_module_opts(opts, :show, conn, resource) do
    opts = get_module_opts(opts, :global, conn)

    quote do
      opts = unquote(opts)
      resource = unquote(resource) |> Alkemist.Controller.load_resource(@resource, opts, @otp_app)
      conn = unquote(conn)

      Alkemist.Controller.opts_or_function(
        opts,
        __MODULE__,
        show_panels: [conn, resource],
        rows: [conn, resource]
      )
      |> Keyword.put(:resource, resource)
    end
  end

  defp get_module_opts(opts, :edit, conn, resource) do
    opts = get_module_opts(opts, :global, conn)

    quote do
      opts = unquote(opts)
      resource = unquote(resource) |> Alkemist.Controller.load_resource(@resource, opts, @otp_app)
      conn = unquote(conn)

      opts =
        opts
        |> Alkemist.Controller.opts_or_function(
          __MODULE__,
          form_partial: [conn, resource],
          fields: [conn, resource]
        )
        |> Keyword.put_new(:changeset, :changeset)
        |> Keyword.put(:resource, resource)

      if is_atom(opts[:changeset]) do
        changeset = apply(@resource, opts[:changeset], [resource, %{}])
        Keyword.put(opts, :changeset, changeset)
      else
        opts
      end
    end
  end

  defp route_params(opts) do
    quote do
      opts = unquote(opts)

      case Keyword.get(opts, :route_params) do
        a when is_list(a) -> a
        b when is_nil(b) -> []
        c -> [c]
      end
    end
  end

  @doc """
  Simple helper method to use link in callbacks
  """
  def link(label, path, opts \\ []) do
    opts = Keyword.put(opts, :to, path)
    Phoenix.HTML.Link.link(label, opts)
  end
end
