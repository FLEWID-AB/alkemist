ExUnit.start()
# Do not run integration tests by default
ExUnit.configure(exclude: [integration: true])

Faker.start()
{:ok, _} = Application.ensure_all_started(:wallaby)
Application.put_env(:wallaby, :base_url, "http://localhost:4002")
TestAlkemist.Application.start(nil, nil)
Ecto.Adapters.SQL.Sandbox.mode(TestAlkemist.Repo, :manual)
