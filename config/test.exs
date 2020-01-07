use Mix.Config

config :alkemist, TestAlkemist.Repo,
  otp_app: :test_alkemist,
  username: System.get_env("PG_USER"),
  password: System.get_env("PG_PASSWORD"),
  database: "alkemist_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :alkemist, ecto_repos: [TestAlkemist.Repo]
config :alkemist, :sql_sandbox, true

config :alkemist, TestAlkemist.Endpoint,
  http: [port: 4002],
  server: true,
  secret_key_base: "PYtsRlPwjiqOjgzIBHCHxQ8CPk9utJdixrwYoQTWZ2FP3cRMlJ3OLJ0ZuJ2m7qwQ"

config :logger, level: :error
