defmodule Alkemist.AuthorizationTest do
  use ExUnit.Case, async: true

  alias Alkemist.Authorization

  defmodule Strict do
    use Alkemist.Authorization

    @impl true
    def authorize_action(_resource, _conn, action), do: action in [:index, :show]

    @impl true
    def current_user_name(_conn), do: "admin"
  end

  defmodule Truthy do
    use Alkemist.Authorization
    @impl true
    def authorize_action(_, _, _), do: "yes"
  end

  test "only a literal true authorises" do
    conn = %Plug.Conn{}
    assert Authorization.authorized?(Strict, Alkemist.Post, conn, :index)
    refute Authorization.authorized?(Strict, Alkemist.Post, conn, :delete)
    refute Authorization.authorized?(Truthy, Alkemist.Post, conn, :index)

    assert Authorization.authorized?(
             Alkemist.Authorization.Permissive,
             Alkemist.Post,
             conn,
             :export
           )
  end

  test "use gives default current_user callbacks that can be overridden" do
    conn = %Plug.Conn{}
    assert Authorization.current_user(Strict, conn) == nil
    assert Authorization.current_user_name(Strict, conn) == "admin"
    assert Authorization.current_user_name(Alkemist.Authorization.Permissive, conn) == nil
  end
end
