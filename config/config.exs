import Config

# This file configures Alkemist's OWN development tooling only. It is not loaded by
# host applications; Alkemist reads host configuration from `config :<otp_app>, Alkemist`.

config :tailwind,
  version: "4.1.12",
  alkemist: [
    args: ~w(--input=css/alkemist.css --output=../priv/static/assets/alkemist.css),
    cd: Path.expand("../assets", __DIR__)
  ]

config :esbuild,
  version: "0.25.0",
  alkemist: [
    args: ~w(js/alkemist.js --bundle --format=esm --target=es2020 --outfile=../priv/static/assets/alkemist.js),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

if Mix.env() == :test do
  import_config "test.exs"
end
