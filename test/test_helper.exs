ExUnit.start()
Faker.start()

Code.require_file("./support/migrations.exs", __DIR__)
Code.require_file("./support/data_case.exs", __DIR__)
Alkemist.Repo.start_link()

Ecto.Adapters.SQL.Sandbox.mode(Alkemist.Repo, :manual)
