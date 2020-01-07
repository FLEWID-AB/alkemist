defmodule Alkemist.Controller do
  @moduledoc """
  Provides helper macros to use inside of CRUD controllers.

  ## Example with minimal configuration:

  ```elixir
  defmodule MyAppWeb.MyController do
    use MyAppWeb, :controller

    # use the automatically generated controller module of your implementation
    # Also pass it the resource (an Ecto Schema of your application) that this controller will handle
    use MyAppWeb.Alkemist.Controller, resource: MyApp.Context.Resource
  end
  ```

  ## Overriding CRUD methods

  By default the controller will define the following default CRUD methods:

  * `index/2` - renders a paginated table
  * `show/2` - shows the details of a specific table row
  * `new/2` - renders the form to create a new item
  * `create/2` - creates a new item from `new/2`
  * `edit/2` - renders the form to edit an existing item
  * `update/2` - updates the item with data from `edit/2`
  * `delete/2` - deletes a resource

  All of the above methods are overridable to customize the behaviour

  ## Example

  ```elixir
    defmodule MyAppWeb.PostController do
      use MyAppWeb.Alkemist.Controller, resource: MyApp.Blog.Post

      # Custom index method
      def index(conn, params) do
        render_index(conn, params, query: MyApp.Blog.published_posts_query()))
      end

      # Custom show method
      def show(conn, %{"id" => id}) do
        post = MyApp.Blog.get_post!(id)

        assigns = Alkemist.Assign.Show(MyAppWeb.Alkemist, post, preload: [:category])

        conn
        |> put_layout({Alkemist.LayoutView})
        |> render("custom_show.html", assigns)
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
  alias Alkemist.{Utils, Assign.Index, Assign.Show, Assign.Form}

  # @callback columns(Plug.Conn.t()) :: [column()]
  # @callback csv_columns(Plug.Conn.t()) :: [column()]
  # @callback fields(Plug.Conn.t(), struct() | nil) :: [field() | map()]
  # @callback scopes(Plug.Conn.t()) :: [scope()]
  # @callback filters(Plug.Conn.t()) :: keyword()
  # @callback repo() :: module()
  # @callback preload() :: keyword()
  # @callback rows(Plug.Conn.t(), struct() | nil) :: list()
  # @callback form_partial(Plug.Conn.t(), struct() | nil) :: tuple()
  # @callback batch_actions() :: keyword()
  # @callback singular_name() :: String.t()
  # @callback plural_name() :: String.t()

  # @optional_callbacks [
  #   columns: 1,
  #   csv_columns: 1,
  #   fields: 2,
  #   scopes: 1,
  #   filters: 1,
  #   repo: 0,
  #   preload: 0,
  #   rows: 2,
  #   form_partial: 2,
  #   batch_actions: 0,
  #   singular_name: 0,
  #   plural_name: 0
  # ]

  # # Type definitions
  # @type scope :: {atom(), keyword(), (%{} -> Ecto.Query.t())}
  # @type column :: atom() | {String.t(), (%{} -> any())}
  # @typedoc """
  # Used to create custom filters in the filter form. Type can be in `[:string, :boolean, :select, :date]`,
  # default is `:string`. If the type is `:select`, a collection to build the select must be passed (see `Phoenix.HTMl.Form.select/4`)
  # """
  # @type filter :: atom() | keyword()
  # @type field :: atom() | {atom(), map()} | %{title: String.t(), fields: [{atom(), map()}]}


  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @implementation Keyword.get(opts, :implementation)
      @resource Keyword.get(opts, :resource)

      default_methods = ~w(index show new create edit update delete)a
      methods = case Keyword.get(opts, :only) do
        a when is_list(a) -> Enum.filter(default_methods, & Enum.member?(a, &1))
        _ -> default_methods
      end

      import Alkemist.Controller
      @behaviour Alkemist.Controller
      import Ecto.Query

      plug Alkemist.Plug, implementation: @implementation, resource: @resource, controller: __MODULE__

      if Enum.member?(methods, :index) do
        def index(conn, params \\ %{}) do
          render_index(conn, params, [])
        end
      end

      if Enum.member?(methods, :show) do
        def show(conn, %{"id" => id}) do
          render_show(conn, id, [])
        end
      end

      if Enum.member?(methods, :new) do
        def new(conn, _params) do
          render_new(conn, [])
        end
      end

      if Enum.member?(methods, :create) do
        def create(conn, params \\ %{}) do
          # resource_params = Map.get(params, "#{Utils.get_struct(@resource)}", %{})
          # do_create(conn, resource_params, [])
        end
      end

      if Enum.member?(methods, :edit) do
        def edit(conn, %{"id" => id}) do
          render_edit(conn, id, [])
        end
      end

      if Enum.member?(methods, :update) do
        def update(conn, %{"id" => id} = params) do
          # resource_params = Map.get(params, "#{Utils.get_struct(@resource)}", %{})
          # do_update(conn, id, resource_params, [])
        end
      end

      if Enum.member?(methods, :delete) do
        def delete(conn, %{"id" => id}) do
          #do_delete(conn, id, [])
        end
      end

      def forbidden(conn) do
        conn
        |> put_status(401)
        |> text("Forbidden")
      end

      defoverridable([forbidden: 1] ++ Enum.map(methods, & {&1, 2}))
    end
  end

  @doc """
  Renders the index view based on the passed options
  """
  @spec render_index(Plug.Conn.t(), map(), keyword()) :: Plug.Conn.t()
  def render_index(%{private: %{alkemist_implementation: implementation, alkemist_resource: resource, alkemist_controller: controller}} = conn, params, opts \\ []) do
    opts = get_module_opts(conn, opts, :index)

    if implementation.authorize_action(conn, resource, :index) do
      assigns = Index.assigns(implementation, resource, opts, params)

      conn
      |> render_template(Keyword.get(opts, :template, "index.html"), assigns)
    else
      controller.forbidden(conn)
    end
  end

  @doc """
  Renders the show view based on the passed options
  """
  @spec render_show(Plug.Conn.t(), any(), keyword()) :: Plug.Conn.t()
  def render_show(%{private: %{alkemist_implementation: implementation, alkemist_resource: resource, alkemist_controller: controller}} = conn, row, opts \\ []) do
    opts = get_module_opts(conn, opts, :show, row)
    row = opts[:resource]

    if row == nil do
      not_found(conn)
    else
      if implementation.authorize_action(conn, row, :show) do
        assigns = Show.assigns(implementation, row, opts)

        conn
        |> render_template(Keyword.get(opts, :template, "show.html"), assigns)
      else
        controller.forbidden(conn)
      end
    end
  end

  @doc """
  Renders the form to create a new table row
  """
  @spec render_new(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def render_new(%{private: %{alkemist_implementation: implementation, alkemist_resource: resource, alkemist_controller: controller}} = conn, opts \\ []) do
    opts = get_module_opts(conn, opts, :new)

    if implementation.authorize_action(conn, resource, :create) do
      render_form(conn, :new, opts)
    else
      controller.forbidden(conn)
    end
  end


  @doc """
  Renders the form to edit a table row
  """
  @spec render_edit(Plug.Conn.t(), String.t() | non_neg_integer() | map(), keyword()) :: Plug.Conn.t()
  def render_edit(%{private: %{alkemist_implementation: implementation, alkemist_controller: controller}} = conn, row, opts \\ []) do
    opts = get_module_opts(conn, opts, :edit, row)
    row = opts[:resource]

    if row == nil do
      not_found(conn)
    else
      if implementation.authorize_action(conn, row, :edit) do
        render_form(conn, :edit, opts)
      else
        controller.forbidden(conn)
      end
    end
  end

  @doc """
  Renders the form for the edit and new actions
  """
  @spec render_form(Plug.Conn.t(), atom(), keyword()) :: Plug.Conn.t()
  def render_form(%{private: %{alkemist_implementation: implementation, alkemist_resource: resource}} = conn, action, opts \\ []) do
    opts = Keyword.put_new(opts, :implementation, implementation)
    assigns = Form.assigns(implementation, resource, opts)

    conn
    |> render_template(Keyword.get(opts, :template, "#{action}.html"), assigns)
  end


  @spec render_template(Plug.Conn.t(), String.t(), keyword()) :: Plug.Conn.t()
  defp render_template(%{private: %{alkemist_implementation: implementation}} = conn, template, assigns) do
    conn
    |> Phoenix.Controller.put_layout(Alkemist.Config.layout(implementation))
    |> Phoenix.Controller.put_view(AlkemistView)
    |> Phoenix.Controller.render(template, assigns)
  end


  # @doc """
  # Creates a new resource
  # """
  # defmacro do_create(conn, params, opts \\ []) do
  #   route_params = route_params(opts)
  #   quote do
  #     conn = unquote(conn)
  #     route_params = unquote(route_params)

  #     if @implementation.authorize_action(conn, @resource, :create) do
  #       opts =
  #         unquote(opts)
  #         |> Keyword.put_new(:changeset, :changeset)
  #         |> Keyword.put_new(:implementation, @implementation)

  #       opts =
  #         if is_atom(opts[:changeset]) do
  #           params = unquote(params)
  #           changeset = apply(@resource, opts[:changeset], [@resource.__struct__, params])
  #           Keyword.put(opts, :changeset, changeset)
  #         else
  #           opts
  #         end

  #       repo = Keyword.get(opts, :repo, Alkemist.Config.repo(@implementation))

  #       case repo.insert(opts[:changeset]) do
  #         {:ok, new_resource} ->
  #           if opts[:success_callback] do
  #             opts[:success_callback].(new_resource)
  #           else
  #             path = String.to_atom("#{Utils.default_resource_helper(@resource, @implementation)}")
  #             params = [conn, :show] ++ route_params ++ [new_resource]
  #             conn
  #             |> Phoenix.Controller.put_flash(
  #               :info,
  #               Utils.singular_name(@resource) <> " created successfully"
  #             )
  #             |> Phoenix.Controller.redirect(
  #               to: apply(Alkemist.Config.router_helpers(@implementation), path, params)
  #             )
  #           end

  #         {:error, changeset} ->
  #           if opts[:error_callback] do
  #             opts[:error_callback].(changeset)
  #           else
  #             opts = [changeset: changeset, route_params: route_params]
  #             render_new(conn, opts)
  #           end
  #       end
  #     else
  #       Alkemist.Controller.forbidden(conn, @implementation)
  #     end
  #   end
  # end

  # @doc """
  # Performs an update to the resource

  # ## Options:

  # * `changeset` - use a custom changeset.
  #   Example: `changeset: :my_update_changeset`
  # * `success_callback` - custom function that will be performed on update success. Accepts the new resource as argument
  # * `error_callback` - custom function that will be performed on failure. Takes the changeset as argument.

  # ## Examples:

  # ```elixir
  # def update(conn, %{"id" => id, "resource" => resource_params}) do
  #   do_update(conn, id, resource_params, changeset: :my_update_changeset)
  # end
  # ```

  # Or use a custom success or error function:

  # ```elixir
  # def update(conn, %{"id" => id, "resource" => resource_params}) do
  #   opts = [
  #     changeset: :my_udpate_changeset
  #     success_callback: fn my_resource ->
  #       conn
  #       |> put_flash(:info, "Resource was successfully updated")
  #       |> redirect(to: my_resource_path(conn, :index))
  #     end
  #   ]
  #   do_update(conn, id, resource_params, opts)
  # end
  # ```
  # """
  # defmacro do_update(conn, resource, params, opts \\ []) do
  #   route_params = route_params(opts)
  #   quote do
  #     conn = unquote(conn)
  #     opts = unquote(opts) |> Keyword.put_new(:implementation, @implementation)
  #     resource = unquote(resource) |> Alkemist.Controller.load_resource(@resource, opts, @implementation)
  #     route_params = unquote(route_params)

  #     if resource == nil do
  #       Alkemist.Controller.not_found(conn)
  #     else
  #       if @implementation.authorize_action(conn, resource, :update) do
  #         params = unquote(params)

  #         opts =
  #           opts
  #           |> Keyword.put_new(:changeset, :changeset)

  #         opts =
  #           if is_atom(opts[:changeset]) do
  #             params = unquote(params)
  #             changeset = apply(@resource, opts[:changeset], [resource, params])
  #             Keyword.put(opts, :changeset, changeset)
  #           else
  #             opts
  #           end

  #         repo = Keyword.get(opts, :repo, Alkemist.Config.repo(@implementation))

  #         case repo.update(opts[:changeset]) do
  #           {:ok, new_resource} ->
  #             if opts[:success_callback] do
  #               opts[:success_callback].(new_resource)
  #             else
  #               path = String.to_atom("#{Utils.default_resource_helper(@resource, @implementation)}")
  #               route_params = [conn, :show] ++ route_params ++ [new_resource]
  #               conn
  #               |> Phoenix.Controller.put_flash(
  #                 :info,
  #                 Utils.singular_name(@resource) <> " updated successfully"
  #               )
  #               |> Phoenix.Controller.redirect(
  #                 to: apply(Alkemist.Config.router_helpers(@implementation), path, route_params)
  #               )
  #             end

  #           {:error, changeset} ->
  #             if opts[:error_callback] do
  #               opts[:error_callback].(changeset)
  #             else
  #               opts = [changeset: changeset, route_params: route_params]
  #               render_edit(conn, resource, opts)
  #             end
  #         end
  #       else
  #         Alkemist.Controller.forbidden(conn, @implementation)
  #       end
  #     end
  #   end
  # end

  # @doc """
  # Performs a delete of the current resource. When successful, it will redirect to index.

  # ## Options:

  # * `delete_func` - use a custom method for deletion. Takes the resource as argument.
  # * `success_callback` - custom function on success. Takes the deleted resource as argument
  # * `error_callback` - custom function on error. Takes the resource as argument

  # ## Examples:

  # ```elixir
  # def delete(conn, %{"id" => id}) do
  #   opts = [
  #     delete_func: fn r ->
  #       MyApp.MyService.deactivate(r)
  #     end,
  #     error_callback: fn r ->
  #       my_custom_error_function(conn, r)
  #     end
  #   ]
  #   do_delete(conn, id, opts)
  # end
  # ```
  # """
  # defmacro do_delete(conn, resource, opts \\ []) do
  #   route_params = route_params(opts)
  #   quote do
  #     conn = unquote(conn)
  #     opts = unquote(opts) |> Keyword.put_new(:implementation, @implementation)
  #     resource = unquote(resource) |> Alkemist.Controller.load_resource(@resource, opts, @implementation)
  #     route_params = unquote(route_params)

  #     if resource == nil do
  #       Alkemist.Controller.not_found(conn)
  #     else
  #       if @implementation.authorize_action(conn, resource, :delete) do
  #         res =
  #           if opts[:delete_func] do
  #             opts[:delete_func].(resource)
  #           else
  #             repo = Keyword.get(opts, :repo, Alkemist.Config.repo(@implementation))
  #             repo.delete(resource)
  #           end

  #         case res do
  #           {:ok, deleted} ->
  #             if opts[:success_callback] do
  #               opts[:success_callback].(deleted)
  #             else
  #               path = String.to_atom("#{Utils.default_resource_helper(@resource)}")
  #               route_params = [conn, :index] ++ route_params

  #               conn
  #               |> Phoenix.Controller.put_flash(
  #                 :info,
  #                 Utils.singular_name(@resource) <> " deleted successfully"
  #               )
  #               |> Phoenix.Controller.redirect(
  #                 to: apply(Alkemist.Config.router_helpers(@implementation), path, route_params)
  #               )
  #             end

  #           {:error, message} ->
  #             if opts[:error_callback] do
  #               opts[:error_callback].(message)
  #             else
  #               path = String.to_atom("#{Utils.default_resource_helper(@resource, @implementation)}")
  #               route_params = [conn, :index] ++ route_params
  #               message =
  #                 if message == :forbidden do
  #                   "You are not authorized to delete this resource"
  #                 else
  #                   "Oops, something went wrong"
  #                 end

  #               conn
  #               |> Phoenix.Controller.put_layout(Alkemist.Config.layout(@implementation))
  #               |> Phoenix.Controller.put_flash(:error, message)
  #               |> Phoenix.Controller.redirect(
  #                 to: apply(Alkemist.Config.router_helpers(@implementation), path, route_params)
  #               )
  #             end
  #         end
  #       else
  #         Alkemist.Controller.forbidden(conn, @implementation)
  #       end
  #     end
  #   end
  # end

  # @doc """
  # Creates a csv export of all entries that match the current scope and filter.
  # An export does not paginate.

  # For available_options see `Alkemist.Controller.render_index/2`
  # """
  # defmacro csv(conn, params, opts \\ []) do
  #   opts = get_module_opts(opts, :export, conn)

  #   quote do
  #     conn = unquote(conn)
  #     opts = unquote(opts) |> Keyword.put_new(:implementation, @implementation)
  #     params = unquote(params)

  #     assigns = Alkemist.Assign.Export.assigns(@implementation, @resource, opts, params)
  #     csv = Alkemist.Export.CSV.create_csv(assigns[:columns], assigns[:entries])

  #     conn
  #     |> Plug.Conn.put_resp_content_type("text/csv")
  #     |> Plug.Conn.put_resp_header("content-disposition", "attachment; filename=\"export.csv\"")
  #     |> Plug.Conn.send_resp(200, csv)
  #   end
  # end

  # # TODO: see if we can make the methods below private somehow
  # def add_opt(opts, controller, key, atts \\ []) do
  #   cond do
  #     Keyword.has_key?(opts, key) ->
  #       opts

  #     Keyword.has_key?(controller.__info__(:functions), key) ->
  #       Keyword.put(opts, key, apply(controller, key, atts))

  #     true ->
  #       opts
  #   end
  # end

  def not_found(conn) do
    conn
    |> Plug.Conn.put_status(:not_found)
    |> Phoenix.Controller.put_view(Alkemist.ErrorView)
    |> Phoenix.Controller.render("404.html")
  end

  @doc """
  Loads the resource from the repo and adds any preloads
  """
  def load_resource(resource, mod, opts, implementation) when is_bitstring(resource),
    do: load_resource(String.to_integer(resource), mod, opts, implementation)

  def load_resource(resource, mod, opts, implementation) when is_integer(resource) do
    repo = Keyword.get(opts, :repo, Alkemist.Config.repo(implementation))
    load_resource(repo.get(mod, resource), mod, opts, implementation)
  end

  def load_resource(resource, _mod, opts, implementation) do
    if opts[:preload] do
      repo = Keyword.get(opts, :repo, Alkemist.Config.repo(implementation))
      resource |> repo.preload(opts[:preload])
    else
      resource
    end
  end

  defp opts_or_function(opts, mod, keys) do
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

  @spec get_module_opts(Plug.Conn.t(), keyword(), atom(), Alkemist.resource()) :: keyword()
  def get_module_opts(conn, opts, type, resource \\ nil)
  def get_module_opts(%{private: %{alkemist_controller: module}}, opts, :global, _resource) do
    opts_or_function(opts, module, [
      :repo,
      :preload,
      :collection_actions,
      :member_actions,
      :batch_actions,
      :singular_name,
      :plural_name
    ])
  end

  def get_module_opts(%{private: %{alkemist_controller: module}} = conn, opts, :index, _resource) do
    opts = get_module_opts(conn, opts, :global)
    opts_or_function(
      opts,
      module,
      columns: [conn],
      scopes: [conn],
      filters: [conn],
      search_provider: []
    )
  end

  def get_module_opts(%{private: %{alkemist_controller: mod, alkemist_implementation: implementation, alkemist_resource: model}} = conn, opts, :show, resource) do
    row = load_resource(resource, model, opts, implementation)

    conn
    |> get_module_opts(opts, :global)
    |> opts_or_function(mod, show_panels: [conn, resource], rows: [conn, resource])
    |> Keyword.put(:resource, row)
  end

  def get_module_opts(%{private: %{alkemist_controller: mod, alkemist_implementation: implementation, alkemist_resource: model}} = conn, opts, :new, _resource) do
    opts = conn
    |> get_module_opts(opts, :global)
    |> opts_or_function(mod, form_partial: [conn, nil], fields: [conn, nil])
    |> Keyword.put_new(:changeset, :changeset)

    if is_atom(opts[:changeset]) do
      changeset = apply(model, opts[:changeset], [model.__struct__, %{}])
      Keyword.put(opts, :changeset, changeset)
    else
      opts
    end
  end

  def get_module_opts(%{private: %{alkemist_controller: mod}} = conn, opts, :export, _resource) do
    conn
    |> get_module_opts(opts, :global)
    |> opts_or_function(mod, [
      {:csv_columns, :columns, [conn]},
      {:columns, [conn]}
    ])
  end


  def get_module_opts(%{private: %{alkemist_controller: mod, alkemist_implementation: implementation, alkemist_resource: model}} = conn, opts, :edit, resource) do
    row = load_resource(resource, model, opts, implementation)

    opts = conn
    |> get_module_opts(opts, :global)
    |> opts_or_function(mod, form_partial: [conn, resource], fields: [conn, resource])
    |> Keyword.put_new(:changeset, :changeset)
    |> Keyword.put(:resource, row)

    if is_atom(opts[:changeset]) do
      changeset = apply(model, opts[:changeset], [row, %{}])
      Keyword.put(opts, :changeset, changeset)
    else
      opts
    end
  end


  # defp route_params(opts) do
  #   quote do
  #     opts = unquote(opts)

  #     case Keyword.get(opts, :route_params) do
  #       a when is_list(a) -> a
  #       b when is_nil(b) -> []
  #       c -> [c]
  #     end
  #   end
  # end

  @doc """
  Simple helper method to use link in callbacks
  """
  def link(label, path, opts \\ []) do
    opts = Keyword.put(opts, :to, path)
    Phoenix.HTML.Link.link(label, opts)
  end
end
