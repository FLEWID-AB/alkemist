ExUnit.start()
Faker.start()

Code.require_file("./support/fixtures.ex", __DIR__)
Code.require_file("./support/data_case.exs", __DIR__)

TestAlkemist.Application.start(nil, nil)
Ecto.Adapters.SQL.Sandbox.mode(TestAlkemist.Repo, :manual)
