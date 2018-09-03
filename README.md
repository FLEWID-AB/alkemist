# Alkemist

Build highly customizable admin interfaces for your Phoenix Applications with ease.

The docs can be found at [https://hexdocs.pm/alkemist](https://hexdocs.pm/alkemist).

## Installation

The package can be installed
by adding `alkemist` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:alkemist, "~> 0.1.0"}
  ]
end
```

To serve the static assets that are included in the package add the following
in your `endpoint.ex`:

```elixir
plug Plug.Static,
    at: "/alkemist", from: :alkemist, gzip: false,
    only: ~w(css fonts images js)
```

Add the application configuration in your `config.exs`:

```elixir
config :alkemist, Alkemist,
  repo: MyApp.Repo,
  router_helpers: MyAppWeb.Router.Helpers,
  title: "My App"
```

## Adding controllers



