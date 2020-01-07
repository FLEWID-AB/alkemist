defmodule Alkemist.ConnCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      use Phoenix.ConnTest
      alias TestAlkemist.Router.Helpers, as: Routes
      @endpoint TestAlkemist.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestAlkemist.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(TestAlkemist.Repo, {:shared, self()})
    end


    current_user = case tags[:user] do
      :none -> nil

      nil ->
        %{username: "AdminUser", role: :admin}

      role when is_atom(role) ->
        %{username: "#{role}User", role: role}

      _ -> %{username: "AdminUser", role: :admin}
    end
    conn = Phoenix.ConnTest.build_conn() |> Plug.Conn.assign(:current_user, current_user)


    {:ok, conn: conn}
  end
end
