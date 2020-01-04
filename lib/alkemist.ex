defmodule Alkemist do
  @moduledoc """
  Alkemist is an admin toolbox for Phoenix applications.
  It allows developers to build admin interfaces in a modular and flexible way
  by providing helper functions to render forms, show- and index pages for resources.

  ## Create your base Admin module for your web context

  Define a module in your application that uses `Alkemist`.

    defmodule MyAppWeb.Alkemist do
      use Alkemist, otp_app: :my_app
    end

  ## Configuration

  The :otp_app option should point to an OTP application that has the alkemist configuration.

    config :my_app, MyAppWeb.Alkemist,
      repo: MyApp.Repo,
      router_helpers: MyAppWeb.Routes

  You can also pass any configuration into the module definition

    defmodule MyApp.Alkemist do
      use Alkemist, otp_app: :my_app, repo: MyApp.Repo
    end

  The configuration options are:

  - `repo`: The Ecto Repo to use. (required)
  - `router_helpers`: The Route helpers module. Default will be `{MyAppWeb}.Routes`
  - `title`: "My Admin Area title". Default will be "Admin"
  - `logo`: Path of a logo image relative to `priv/static` of your module's OTP app. Default `false`

  """

  @typedoc """
  Custom type for resources. A resource can either be a map, Ecto.Struct definition, or an Ecto Schema implementation
  """
  @type resource :: module() | map()

  def view do
    quote do
      use Phoenix.View, root: "lib/alkemist/templates", namespace: Alkemist

      import Phoenix.Controller, only: [get_flash: 2, view_module: 1]
      use Phoenix.HTML
      import Alkemist.Router.Helpers
      import Alkemist.ViewHelpers
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(opts \\ [])
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro __using__(opts) do
    otp_app = Keyword.get(opts, :otp_app)

    # credo:disable-for-next-line Credo.Check.Refactor.LongQuoteBlocks
    quote do

      __MODULE__
      |> Module.concat(:Controller)
      |> Module.create(
        quote do
          defmacro __using__(opts \\ []) do
            implementation =
              __MODULE__
              |> Module.split()
              |> Enum.drop(-1)
              |> Enum.join(".")
              |> String.replace_prefix("", "Elixir.")
              |> String.to_existing_atom()

            resource = Keyword.get(opts, :resource)
            quote do
              @implementation unquote(implementation)
              @resource unquote(resource)

              use Alkemist.Controller, implementation: @implementation

              def index(conn, params \\ %{}) do
                conn
                |> text("index")
              end

              def show(conn, params \\ %{}) do
                conn
                |> text("Show")
              end

              def columns(_conn) do
                Alkemist.Utils.display_fields(@resource)
              end

              defoverridable([
                index: 2,
                show: 2,
                columns: 1
              ])
            end
          end
        end,
        Macro.Env.location(__ENV__)
      )

      def otp_app, do: unquote(otp_app)

      def config do
        unquote(otp_app)
        |> Application.get_env(__MODULE__, [])
        |> Keyword.merge(unquote(opts))
      end

      def config(key, default \\ nil),
        do: config() |> Keyword.get(key, default)


      @doc """
      Returns the current user object. Override to retrieve your current user from the conn

      ## Example

      ```elixir
        def current_user(conn), do: conn.assigns.current_user
      ```
      """
      @spec current_user(Plug.Conn.t()) :: map() | nil
      def current_user(_conn), do: nil

      @doc """
      Returns the current user's name. Meant to be overridden in an application with authentication

      ## Example

      ```elixir
        def current_user_name(conn) do
          case current_user(conn) do
            nil -> nil
            user -> user.username
          end
        end
      ```
      """
      @spec current_user_name(Plug.Conn.t()) :: String.t() | nil
      def current_user_name(_conn), do: nil

      @doc """
      Authorize a user to perform `action` on `resource`. Override this method to
      implement custom authorization actions

      ## Example

      ### Implement a custom authorization module or e. g. use `canary`

      ```elixir
        defmodule MyApp.Authorization do
          def can?(%{role: :superadmin}, _, _), do: true

          def can?(%{role: :admin}, Alkemist.Post, :index), do: false
        end
      ```

      ### In your `Alkemist` implementation module

      ```elixir
        defmodule MyAppWeb.Authorization do
          use Alkemist, otp_app: :my_app

          def current_user(conn), do: Map.get(conn.assigns, :current_user)

          def authorize_action(conn, resource, action) do
            MyApp.Authorization.can?(current_user(conn), resource, action)
          end
        end
      ```
      """
      @spec authorize_action(Plug.Conn.t(), Alkemist.resource() | nil, atom()) :: boolean()
      def authorize_action(_conn, _resource, _action), do: true

      defoverridable([
        current_user: 1,
        current_user_name: 1,
        authorize_action: 3
      ])
    end
  end
end
