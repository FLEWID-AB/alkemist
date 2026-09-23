{:ok, _} = Alkemist.Repo.start_link()
{:ok, _} = AlkemistTest.Endpoint.start_link()
Ecto.Adapters.SQL.Sandbox.mode(Alkemist.Repo, :manual)
ExUnit.start()
