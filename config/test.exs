use Mix.Config

config :alkemist, TestAlkemist.Repo,
  otp_app: :test_alkemist,
  username: System.get_env("PG_USER"),
  password: System.get_env("PG_PASSWORD"),
  database: "alkemist_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :alkemist, ecto_repos: [TestAlkemist.Repo]

config :alkemist, TestAlkemist.Endpoint,
  http: [port: 4002],
  server: true

config :logger, level: :error
