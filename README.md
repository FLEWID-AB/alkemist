# Alkemist

Build admin interfaces for Phoenix applications from thin controllers: index tables with
search, filters, scopes, sorting, pagination and CSV export; show pages; create/edit forms
with nested associations; a sidebar menu; authorization hooks. Rendered with Phoenix
components and Tailwind CSS, themeable without rebuilding.

Documentation: [hexdocs.pm/alkemist](https://hexdocs.pm/alkemist). Upgrading from 2.x:
see `guides/upgrading_to_3_0.md`.

## Installation

```elixir
def deps do
  [
    {:alkemist, "~> 3.0"}
  ]
end
```

Requires Elixir 1.16+, Phoenix 1.7.11+ (1.8 recommended), Ecto SQL 3.11+ and Postgres.

## Setup

1. **Config** (`config/config.exs`):

   ```elixir
   config :my_app, Alkemist,
     repo: MyApp.Repo,
     title: "MY APP",
     subtitle: "Admin",
     authorization_provider: MyAppWeb.AlkemistAuthorization,  # optional
     sign_out: [path: "/logout", method: :delete]              # optional
   ```

   The key is your own OTP app; pass it to controllers with `otp_app: :my_app`.

2. **Assets** (`lib/my_app_web/endpoint.ex`). Alkemist ships a prebuilt stylesheet and script:

   ```elixir
   plug Plug.Static, at: "/alkemist", from: :alkemist, gzip: true, only: ~w(assets)
   ```

   Hosts that compile Tailwind themselves can instead add `@source "../../deps/alkemist/lib";`
   and `@import "../../deps/alkemist/assets/css/alkemist-theme.css";` to their `app.css`,
   import the hooks from `deps/alkemist/assets/js/hooks/index.js`, and set
   `assets: [css: "/assets/app.css", js: "/assets/app.js"]` in the config.

3. **Router**:

   ```elixir
   use Alkemist.Router

   scope "/admin", MyAppWeb.Admin do
     pipe_through :browser
     alkemist_resources "/posts", PostController
   end
   ```

4. **Controller**, generated with `mix alkemist.gen.controller Post MyApp.Blog.Post Admin`
   or written by hand:

   ```elixir
   defmodule MyAppWeb.Admin.PostController do
     use MyAppWeb, :controller

     @resource MyApp.Blog.Post
     use Alkemist.Controller, otp_app: :my_app

     menu "Posts", parent: "Blog", icon: "hero-document-text"

     def index(conn, params), do: render_index(conn, params, description: "All published and draft posts.")
     def show(conn, %{"id" => id}), do: render_show(conn, id, title: & &1.title)
     def new(conn, _), do: render_new(conn)
     def edit(conn, %{"id" => id}), do: render_edit(conn, id)
     def create(conn, %{"post" => params}), do: do_create(conn, params)
     def update(conn, %{"id" => id, "post" => params}), do: do_update(conn, id, params)
     def delete(conn, %{"id" => id}), do: do_delete(conn, id)
     def export(conn, params), do: csv(conn, params)

     @impl true
     def columns(_conn), do: [:id, :title, {"Category", fn p -> p.category.name end}, :published_at]

     @impl true
     def filters(_conn), do: [title: %{primary: true}, published: %{type: :boolean}, published_at: %{type: :datetime}]

     @impl true
     def preload, do: [:category]
   end
   ```

## Customising the look

Colours, radius and fonts are CSS custom properties; override them in any stylesheet loaded
after Alkemist's:

```css
:root { --ak-brand: #C8102E; --ak-radius: 8px; }
```

Markup is changed through a theme module:

```elixir
defmodule MyAppWeb.AlkemistTheme do
  use Alkemist.Theme

  @impl true
  def brand(assigns), do: ~H|<a href="/admin" class="ak-brand"><img src="/images/logo.svg" alt="My App" /></a>|
end

config :my_app, Alkemist, theme: MyAppWeb.AlkemistTheme
```

See `Alkemist.Theme` for every callback and `guides/theming.md` for the two asset modes.

## Development

```
docker compose up -d db          # Postgres on port 1234
PG_PORT=1234 mix test
mix assets.setup && mix assets.build   # rebuild priv/static/assets after changing CSS, JS or templates
```
