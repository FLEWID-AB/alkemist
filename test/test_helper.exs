ExUnit.start()

Code.require_file("./support/repo.ex", __DIR__)
Code.require_file("./support/migrations.exs", __DIR__)
Code.require_file("./support/data_case.exs", __DIR__)
Code.require_file("./support/models/post.ex", __DIR__)
Alkemist.Repo.start_link()
_ = Ecto.Migrator.up(Alkemist.Repo, 0, Alkemist.Migrations, log: false)
Ecto.Adapters.SQL.Sandbox.mode(Alkemist.Repo, :manual)
