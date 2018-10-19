use Mix.Config

config :alkemist, Alkemist,
  router_helpers: AlkemistTest.Router.Helpers,
  repo: Alkemist.Repo

config :alkemist, ecto_repos: [Alkemist.Repo]

config :alkemist, Alkemist.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("PG_USER"),
  password: System.get_env("PG_PASSWORD"),
  database: "alkemist_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
