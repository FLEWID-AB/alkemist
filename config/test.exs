import Config

config :alkemist, Alkemist, repo: Alkemist.Repo

config :alkemist, ecto_repos: [Alkemist.Repo]

config :alkemist, Alkemist.Repo,
  otp_app: :alkemist,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("PG_USER") || "postgres",
  password: System.get_env("PG_PASSWORD") || "postgres",
  database: "alkemist_test",
  hostname: "localhost",
  port: System.get_env("PG_PORT") || "1234",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "test/support/repo"

config :alkemist, AlkemistTest.Endpoint,
  secret_key_base: String.duplicate("alkemist-test-secret", 4),
  server: false,
  render_errors: [formats: [html: Alkemist.ErrorHTML]]

config :logger, level: :warning
