defmodule Alkemist.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias TestAlkemist.Repo
      import Ecto.Query
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestAlkemist.Repo)
    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(TestAlkemist.Repo, {:shared, self()})
    end

    :ok
  end
end
