defmodule Alkemist.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL

      alias TestAlkemist.Repo
      alias TestAlkemist.Router.Helpers, as: Routes
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestAlkemist.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(TestAlkemist.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(TestAlkemist.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)

    {:ok, session: session}
  end
end
