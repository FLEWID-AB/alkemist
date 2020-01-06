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

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
