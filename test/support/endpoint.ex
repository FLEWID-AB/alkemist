defmodule AlkemistTest.Endpoint do
  @moduledoc "Minimal endpoint so request tests go through a real router and flash."
  use Phoenix.Endpoint, otp_app: :alkemist

  @session_options [
    store: :cookie,
    key: "_alkemist_test_key",
    signing_salt: "alkemist-test",
    same_site: "Lax"
  ]

  plug(Plug.Parsers, parsers: [:urlencoded, :multipart], pass: ["*/*"])
  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(AlkemistTest.Router)
end
