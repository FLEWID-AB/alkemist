defmodule Alkemist.Authorization do
  @moduledoc """
  Behaviour for the authorization provider Alkemist consults before every action.

  Configure it with

      config :my_app, Alkemist, authorization_provider: MyAppWeb.AlkemistAuthorization

  and implement it like

      defmodule MyAppWeb.AlkemistAuthorization do
        use Alkemist.Authorization

        @impl true
        def authorize_action(_resource, conn, action) do
          action in MyApp.Accounts.permissions(conn.assigns.current_user)
        end

        @impl true
        def current_user(conn), do: conn.assigns[:current_user]

        @impl true
        def current_user_name(conn), do: current_user(conn) && current_user(conn).email
      end

  `resource` is the schema module for `:index`, `:create` and `:export`, and the loaded
  record for `:show`, `:update` and `:delete`. Only a literal `true` authorises.
  `Alkemist.Authorization.Permissive` is the default provider and allows everything.
  """

  @type action :: :index | :show | :create | :update | :delete | :export | atom()

  @doc "Whether the current request may perform `action` on `resource`."
  @callback authorize_action(resource :: module() | struct(), Plug.Conn.t(), action()) ::
              boolean()

  @doc "The current user, or `nil`."
  @callback current_user(Plug.Conn.t()) :: term() | nil

  @doc "A display name for the current user, or `nil`."
  @callback current_user_name(Plug.Conn.t()) :: String.t() | nil

  @optional_callbacks current_user: 1, current_user_name: 1

  defmacro __using__(_opts) do
    quote do
      @behaviour Alkemist.Authorization

      @impl Alkemist.Authorization
      def current_user(_conn), do: nil

      @impl Alkemist.Authorization
      def current_user_name(_conn), do: nil

      defoverridable current_user: 1, current_user_name: 1
    end
  end

  @doc "Asks `provider` and returns `true` only for a literal `true`."
  @spec authorized?(module(), module() | struct(), Plug.Conn.t(), action()) :: boolean()
  def authorized?(provider, resource, conn, action) do
    provider.authorize_action(resource, conn, action) == true
  end

  @doc "The current user according to `provider` (`nil` when the callback is not implemented)."
  @spec current_user(module(), Plug.Conn.t()) :: term() | nil
  def current_user(provider, conn) do
    if function_exported?(provider, :current_user, 1), do: provider.current_user(conn)
  end

  @doc "The current user's display name according to `provider`."
  @spec current_user_name(module(), Plug.Conn.t()) :: String.t() | nil
  def current_user_name(provider, conn) do
    if function_exported?(provider, :current_user_name, 1), do: provider.current_user_name(conn)
  end
end

defmodule Alkemist.Authorization.Permissive do
  @moduledoc "The default authorization provider: every action is allowed, there is no current user."
  use Alkemist.Authorization

  @impl true
  def authorize_action(_resource, _conn, _action), do: true
end
