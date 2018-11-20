# Alkemist

Build highly customizable admin interfaces for your Phoenix Applications with ease.

The docs can be found at [https://hexdocs.pm/alkemist](https://hexdocs.pm/alkemist).

## Installation

The package can be installed
by adding `alkemist` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:alkemist, "~> 1.0.1-rc"}
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

Alkemist comes with a generator for new controllers. You can use it as follows: 

```
mix alkemist.gen.controller ControllerName MyApp.ModelName
```

Or to generate the controller in a certain namespace:

```
mix alkemist.gen.controller ControllerName MyApp.ModelName MyNamespace
```

This will generate the file at `controllers/my_namespace/controller_name_controller.ex`

Of course you can also add custom written controllers as well by starting from scratch or using the phoenix generator.

