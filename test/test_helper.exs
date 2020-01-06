ExUnit.start()
Faker.start()

TestAlkemist.Application.start(nil, nil)
Ecto.Adapters.SQL.Sandbox.mode(TestAlkemist.Repo, :manual)
