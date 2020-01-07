defmodule TestAlkemist.Endpoint do
  use Phoenix.Endpoint, otp_app: :alkemist

  plug Plug.Static,
    at: "/alkemist/",
    from: :alkemist,
    gzip: false,
    only: ~w(css fonts images js)

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  if Application.get_env(:alkemist, :sql_sandbox) do
    plug Phoenix.Ecto.SQL.Sandbox
  end

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_test_alkemist_key",
    signing_salt: "/gcR1X+K"

  plug TestAlkemist.Router
end
