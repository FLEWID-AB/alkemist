# Upgrading to Alkemist 3.0

3.0 is a clean break: the rendering layer moved from Phoenix.View/EEx/Bootstrap to Phoenix
components and Tailwind, the query layer no longer uses Flop or Turbo.Ecto, and paths are
derived from your router. The controller macros and their option shapes (`columns`, `rows`,
`fields`, `scopes`, `filters`, `member_actions`, `collection_actions`, `batch_actions`,
`preload`, `repo`, `route_params`, `changeset`, `success_callback`, `error_callback`) are
unchanged, so most controllers compile as they are. Work through the list below.

## 1. Dependencies

```elixir
{:alkemist, "~> 3.0"}
```

Alkemist now requires `phoenix ~> 1.7.11 or ~> 1.8`, `phoenix_html ~> 4.1`,
`phoenix_live_view ~> 1.0` (for `Phoenix.Component`; no LiveView sockets are needed) and
Elixir 1.16+. Remove `phoenix_view` and `phoenix_mtm` from your own deps if only Alkemist
needed them. If your changesets used `PhoenixMTM.Changeset.cast_collection/4`, switch to
`Ecto.Changeset.put_assoc/3` (the many-to-many checkbox group submits a list of ids under
the association name, with an empty string when nothing is checked).

## 2. Configuration

Keys that were removed raise at startup with a pointer:

| removed | replacement |
|---|---|
| `router_helpers`, `route_prefix` | none: paths come from `Alkemist.Routes` (see 4) |
| `web_interface`, `json_library` | none: the menu file cache is gone |
| `views: [...]` | a `theme:` module (see 5) or `root_layout:` |
| `decorators: [...]` | theme callbacks `value/1`, `row_class/2`, `member_actions/1`, `filter_field/1`, `form_field/1` |

New keys: `theme`, `root_layout`, `assets`, `home_path`, `subtitle`, `environment`,
`sign_out`, `forbidden_redirect_to`, `timezone`, `pagination`, `csv`, `menu_cache`. Unknown keys raise. `repo` is required. `logo` is now a
full path served by your app (`"/images/logo.svg"`), not a file name under `/images/`.
Configuration is read per OTP app: `config :my_app, Alkemist, ...` is used by controllers
declared with `use Alkemist.Controller, otp_app: :my_app`; without `otp_app:` the
`:alkemist` app is read.

## 3. Endpoint and assets

```elixir
plug Plug.Static, at: "/alkemist", from: :alkemist, gzip: true, only: ~w(assets)
```

The bundle moved to `/alkemist/assets/alkemist.css` and `/alkemist/assets/alkemist.js`
(was `css/`, `js/`, `fonts/`). Font Awesome, jQuery, CoreUI and Bootstrap are gone. See
`guides/theming.md` for compiling Alkemist's templates with your own Tailwind build.

## 4. Router

`use Phoenix.Router, helpers: true` is no longer required. Paths are found in the router's
route table for the controller that rendered the page, so the schema's table name no
longer has to match the route name and `route_prefix` is unnecessary. Custom member,
collection and batch actions still need a route for `{controller, action}`; a controller
may define `path_for(conn, action, route_params, query)` to build paths itself.

`forbidden/2` no longer redirects to `page_path(conn, :dashboard)`; set
`forbidden_redirect_to: "/admin"` (or `{Mod, :fun}`, or `:render` for a 403 page).

## 5. Templates and decorators become a theme

Create one module:

```elixir
defmodule MyAppWeb.AlkemistTheme do
  use Alkemist.Theme

  @impl true
  def brand(assigns), do: ~H|<a href="/admin" class="ak-brand">My App</a>|

  @impl true
  def account(assigns) do
    ~H"""
    <.account_footer name={@current_user_name} environment="Production" sign_out={[path: "/logout", method: :delete]} />
    """
  end

  @impl true
  def value(%{value: %Money{}} = assigns), do: ~H|<span class="tabular-nums">{Money.to_string(@value)}</span>|
  def value(assigns), do: Alkemist.Theme.Default.value(assigns)
end
```

Mapping from 2.x:

| 2.x | 3.0 callback |
|---|---|
| `views[:layout]` | `app/1` (the shell) or `root_layout:` config for the `<html>` wrapper |
| `views[:left_header]` | `brand/1` (now at the top of the sidebar; also `title`/`subtitle`/`logo` config) |
| `views[:right_header]` | `account/1`, the sidebar footer (or `environment`/`sign_out` config); there is no top header bar |
| `views[:sidebar]` | `sidebar/1` |
| `views[:aside]` | `aside/1` |
| `views[:styles]`, `views[:scripts]` | `head/1` or the `assets:` config |
| `views[:filter]`, `decorators[:filter]` | `filters/1`, `filter_field/1` |
| `views[:pagination]` | `pagination/1` |
| `decorators[:field_value]` | `value/1` |
| `decorators[:row_class]` | `row_class/2` |
| `decorators[:member_actions]` | `member_actions/1` (`header?` for the `<th>`) |
| `decorators[:form]` | `form_field/1`; per field `component:` option |
| `form_partial: {View, "form.html"}` | `form_partial: {Module, :fun}` or `&Module.fun/1`, a HEEx component receiving `form`, `action`, `form_method`, `form_fields`, `struct`, `paths` |
| `show_panels`/`sidebars` `partial:` | `component: {Module, :fun}`; `content:` is escaped unless `{:safe, _}` |

`get_flash/2` is gone; use `@flash` with `Phoenix.Flash.get/2`.

## 6. Layout and look

The 2.x CoreUI layout (top header bar, grey sidebar, Bootstrap cards) is replaced by the
3.0 design: a sidebar with brand, grouped navigation and account footer; a white header
band per page; IBM Plex type. Row actions moved into a "⋯" menu; filters became a search
box plus dropdown buttons (same query parameters); dates render as `YYYY-MM-DD` and
`YYYY-MM-DD HH:MM`; flashes are toasts. See `guides/theming.md`.

## 7. Escaping

Cell values are escaped. Column callbacks that returned HTML strings must return `raw/1` or
`~H` explicitly. Labels are text; icons are Heroicons names (`icon: "hero-pencil-square"`),
Font Awesome classes raise.

## 8. Authorization

`Alkemist.Authorization` is a behaviour: `use Alkemist.Authorization` and add `@impl true`.
The `:export` action is now checked (CSV) as is `render_form/3`. Only a literal `true`
authorises.

## 9. Query behaviour changes

- Association filters work for every association as `<assoc>_assoc_<field>_<op>`; the old
  hardcoded `subscriber`/`subscription` list is gone.
- `start`/`end` really mean starts/ends with; `not_*` operators parse correctly; new
  `null`/`not_null` and `not_in`.
- Date-only values on datetime columns are half-open day intervals; `lteq` is inclusive of
  the whole day.
- Unknown fields and uncastable values are ignored instead of raising.
- `per_page` is capped by `pagination[:max_per_page]` (default 100); the default sort is
  the primary key descending.
- `Search.run/2`/`searchq/2`/`sortq/2` are deprecated in favour of `run/3`, `filter/3`,
  `sort/3`; custom providers implement `Alkemist.Query.SearchProvider` /
  `Alkemist.Query.PaginationProvider`.

## 10. Other breaking details

- Form param key comes from the module name (`MyApp.Blog.Post` → `"post"`); override with
  `resource_key/0` if your table name was used before.
- `do_delete`'s `error_callback` receives `(resource, reason)`.
- CSV: streamed, CRLF line endings, filename `<table>-<date>.csv`, `csv:` config for
  separator/BOM; `Alkemist.Export.CSV.create_csv/2` is deprecated.
- Records are loaded by primary key type; malformed ids answer 404.
- The sidebar is built from the router at runtime (`Alkemist.Menu`); `menu/2` semantics are
  unchanged.
