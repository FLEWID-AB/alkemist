defmodule Alkemist.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Alkemist.Repo
      import Ecto.Query
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Alkemist.Repo)
    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Alkemist.Repo, {:shared, self()})
    end

    :ok
  end
end
