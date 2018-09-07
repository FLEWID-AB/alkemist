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

    # use if you want to customize the menu
    menu "My Custom Label"

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
  """

  alias Alkemist.Assign
  alias Alkemist.Utils

  # Type definitions
  @type scope :: {atom(), keyword(), (%{} -> Ecto.Query.t())}
  @type column :: atom() | {String.t(), (%{} -> any())}
  @typedoc """
  Used to create custom filters in the filter form. Type can be in `[:string, :boolean, :select, :date]`,
  default is `:string`. If the type is `:select`, a collection to build the select must be passed (see `Phoenix.HTMl.Form.select/4`)
  """
  @type filter ::
          {atom(),
           %{
             optional(:label) => String.t(),
             optional(:type) => atom(),
             optional(:collection) => []
           }}
  @type field :: {atom(), map()}

  defmacro __using__(_) do
    Code.ensure_compiled(Alkemist.MenuRegistry)

    quote do
      import Alkemist.Assign
      import Alkemist.Controller
      import Ecto.Query

      if @resource !== nil do
        menu(Alkemist.Utils.plural_name(@resource))
      end
    end
  end

  @doc """
  Customize the Menu item in the sidebar.
  You can call this function within the controller root
  after including Alkemist.Controller and setting the @resource

  ## Examples:

  ### Display no menu:

  ```elixir
  menu false
  ```

  ### Display a custom label:

  ```elixir
  menu "My Custom Menu Label"
  ```

  ### Add this menu item to a dropdown menu:

  If the same label for the parent is used multiple times, all menu items with the same parent will be grouped under it

  ```elixir
  menu "Label", parent: "Dropdown Menu Title"
  ```

  ### Alter the order and the order of the parent within the sidebar:

  ```elixir
  menu "Label", parent: "Parent", index: 2, parent_index: 1
  ```
  """
  defmacro menu(label, opts \\ []) do
    quote do
      label = unquote(label)
      opts = unquote(opts) |> Keyword.put(:resource, @resource)
      Alkemist.MenuRegistry.register_menu_item(__MODULE__, label, opts)
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
  ```
  """
  defmacro render_index(conn, params, opts \\ []) do
    opts = get_module_opts(opts, :index, conn)

    quote do
      conn = unquote(conn)

      if Alkemist.Config.authorization_provider().authorize_action(@resource, conn, :index) ==
           true do
        opts = unquote(opts)

        assigns = Assign.index_assigns(unquote(params), @resource, opts)

        assigns =
          if Keyword.has_key?(__MODULE__.__info__(:functions), :export) do
            Keyword.put(assigns, :has_export, true)
          else
            assigns
          end

        conn
        |> Phoenix.Controller.put_layout(Alkemist.Config.layout())
        |> Phoenix.Controller.render(AlkemistView, "index.html", assigns)
      else
        Alkemist.Controller.forbidden(conn)
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
      opts = unquote(opts)
      resource = opts[:resource]

      if resource == nil do
        Alkemist.Controller.not_found(conn)
      else
        if Alkemist.Config.authorization_provider().authorize_action(resource, conn, :show) do
          assigns = Assign.show_assigns(resource, opts)

          conn
          |> Phoenix.Controller.put_layout(Alkemist.Config.layout())
          |> Phoenix.Controller.render(AlkemistView, "show.html", assigns)
        else
          Alkemist.Controller.forbidden(conn)
        end
      end
    end
  end

  @doc """
  Renders the "new" action
  TODO: document opts
  """
  defmacro render_new(conn, opts \\ []) do
    opts = get_module_opts(opts, :new, conn)

    quote do
      conn = unquote(conn)
      opts = unquote(opts)

      if Alkemist.Config.authorization_provider().authorize_action(@resource, conn, :create) do
        render_form(conn, :new, opts)
      else
        Alkemist.Controller.forbidden(conn)
      end
    end
  end

  @doc """
  Renders the "edit action"
  TODO: document opts
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
        if Alkemist.Config.authorization_provider().authorize_action(resource, conn, :update) do
          render_form(conn, :edit, opts)
        else
          Alkemist.Controller.forbidden(conn)
        end
      end
    end
  end

  @doc """
  Renders the form
  TODO: document opts
  """
  defmacro render_form(conn, action, opts \\ []) do
    quote do
      opts = unquote(opts)
      action = unquote(action)

      assigns = Assign.form_assigns(@resource, opts)
      conn = unquote(conn)

      conn
      |> Phoenix.Controller.put_layout(Alkemist.Config.layout())
      |> Phoenix.Controller.render(AlkemistView, "#{action}.html", assigns)
    end
  end

  @doc """
  Creates a new resource
  TODO: document opts
  """
  defmacro do_create(conn, params, opts \\ []) do
    quote do
      conn = unquote(conn)

      if Alkemist.Config.authorization_provider().authorize_action(@resource, conn, :create) do
        opts =
          unquote(opts)
          |> Keyword.put_new(:changeset, :changeset)

        opts =
          if is_atom(opts[:changeset]) do
            params = unquote(params)
            changeset = apply(@resource, opts[:changeset], [@resource.__struct__, params])
            Keyword.put(opts, :changeset, changeset)
          else
            opts
          end

        repo = Keyword.get(opts, :repo, Alkemist.Config.repo())

        case repo.insert(opts[:changeset]) do
          {:ok, new_resource} ->
            if opts[:success_callback] do
              opts[:success_callback].(new_resource)
            else
              path = String.to_atom("#{Utils.get_struct(@resource)}_path")

              conn
              |> Phoenix.Controller.put_flash(
                :info,
                Utils.singular_name(@resource) <> " created successfully"
              )
              |> Phoenix.Controller.redirect(
                to: apply(Alkemist.Config.router_helpers(), path, [conn, :show, new_resource])
              )
            end

          {:error, changeset} ->
            if opts[:error_callback] do
              opts[:error_callback].(changeset)
            else
              opts = [changeset: changeset]
              render_new(conn, opts)
            end
        end
      else
        Alkemist.Controller.forbidden(conn)
      end
    end
  end

  @doc """
  Performs an update to the resource
  TODO: document opts
  """
  defmacro do_update(conn, resource, params, opts \\ []) do
    quote do
      conn = unquote(conn)
      opts = unquote(opts)
      resource = unquote(resource) |> Alkemist.Controller.load_resource(@resource, opts)

      if resource == nil do
        Alkemist.Controller.not_found(conn)
      else
        if Alkemist.Config.authorization_provider().authorize_action(resource, conn, :update) do
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

          repo = Keyword.get(opts, :repo, Alkemist.Config.repo())

          case repo.update(opts[:changeset]) do
            {:ok, new_resource} ->
              if opts[:success_callback] do
                opts[:success_callback].(new_resource)
              else
                path = String.to_atom("#{Utils.get_struct(@resource)}_path")

                conn
                |> Phoenix.Controller.put_flash(
                  :info,
                  Utils.singular_name(@resource) <> " updated successfully"
                )
                |> Phoenix.Controller.redirect(
                  to: apply(Alkemist.Config.router_helpers(), path, [conn, :show, new_resource])
                )
              end

            {:error, changeset} ->
              if opts[:error_callback] do
                opts[:error_callback].(changeset)
              else
                opts = [changeset: changeset]
                render_edit(conn, resource, opts)
              end
          end
        else
          Alkemist.Controller.forbidden(conn)
        end
      end
    end
  end

  @doc """
  TODO: document opts
  """
  defmacro do_delete(conn, resource, opts \\ []) do
    quote do
      conn = unquote(conn)
      opts = unquote(opts)
      resource = unquote(resource) |> Alkemist.Controller.load_resource(@resource, opts)

      if resource == nil do
        Alkemist.Controller.not_found(conn)
      else
        if Alkemist.Config.authorization_provider().authorize_action(resource, conn, :delete) do
          res =
            if opts[:delete_func] do
              opts[:delete_func].(resource)
            else
              repo = Keyword.get(opts, :repo, Alkemist.Config.repo())
              repo.delete(resource)
            end

          case res do
            {:ok, deleted} ->
              if opts[:success_callback] do
                opts[:success_callback].(deleted)
              else
                path = String.to_atom("#{Utils.get_struct(@resource)}_path")

                conn
                |> Phoenix.Controller.put_flash(
                  :info,
                  Utils.singular_name(@resource) <> " deleted successfully"
                )
                |> Phoenix.Controller.redirect(
                  to: apply(Alkemist.Config.router_helpers(), path, [conn, :index])
                )
              end

            {:error, message} ->
              if opts[:error_callback] do
                opts[:error_callback].(message)
              else
                path = String.to_atom("#{Utils.get_struct(@resource)}_path")

                message =
                  if message == :forbidden do
                    "You are not authorized to delete this resource"
                  else
                    "Oops, something went wrong"
                  end

                conn
                |> Phoenix.Controller.put_layout(Alkemist.Config.layout())
                |> Phoenix.Controller.put_flash(:error, message)
                |> Phoenix.Controller.redirect(
                  to: apply(Alkemist.Config.router_helpers(), path, [conn, :index])
                )
              end
          end
        else
          Alkemist.Controller.forbidden(conn)
        end
      end
    end
  end

  @doc """
  TODO: document opts
  """
  defmacro csv(conn, params, opts \\ []) do
    opts = get_module_opts(opts, :export, conn)

    quote do
      conn = unquote(conn)
      opts = unquote(opts)
      params = unquote(params)

      assigns = Assign.csv_assigns(params, @resource, opts)
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

  def forbidden(conn) do
    conn
    |> Phoenix.Controller.put_layout(Alkemist.Config.layout())
    |> Phoenix.Controller.put_flash(:error, "You are not authorized to access this page")
    |> Phoenix.Controller.redirect(
      to: Alkemist.Config.router_helpers().page_path(conn, :dashboard)
    )
  end

  def not_found(conn) do
    conn
    |> Plug.Conn.put_status(:not_found)
    |> Phoenix.Controller.render(Alkemist.ErrorView, "404.html")
  end

  @doc """
  Loads the resource from the repo and adds any preloads
  """
  def load_resource(resource, mod, opts) when is_bitstring(resource),
    do: load_resource(String.to_integer(resource), mod, opts)

  def load_resource(resource, mod, opts) when is_integer(resource) do
    repo = Keyword.get(opts, :repo, Alkemist.Config.repo())
    load_resource(repo.get(mod, resource), mod, opts)
  end

  def load_resource(resource, _mod, opts) do
    if opts[:preload] do
      repo = Keyword.get(opts, :repo, Alkemist.Config.repo())
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

      Alkemist.Controller.opts_or_function(opts, __MODULE__, [:repo, :preload])
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
      resource = unquote(resource) |> Alkemist.Controller.load_resource(@resource, opts)
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
      resource = unquote(resource) |> Alkemist.Controller.load_resource(@resource, opts)
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
end
