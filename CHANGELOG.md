# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [3.0.0] - Unreleased

A clean break from 2.x; read `guides/upgrading_to_3_0.md` before upgrading. The
"Status" note at the end of this section tracks what is left before the tag.

### Added
- **Visual design from the admin UI kit** (`raw/new-theme` in the project wiki): ten
  semantic tokens plus derived shades (`--ak-bg`, `--ak-surface`, `--ak-border`,
  `--ak-text`, `--ak-muted`, `--ak-brand`, `--ak-primary`, `--ak-ok|info|warn|danger` with
  `-soft`/`-dot` variants), a hand-tuned dark set, 6/8 px radii, IBM Plex Sans (variable)
  and Plex Mono shipped as woff2 (OFL). Layout: 232 px sidebar with brand, grouped
  collapsible navigation (menu `icon:` option) and account footer; per-page white header
  band with back link, description, actions and tabs; no top header bar. Index: search box
  plus dropdown filter buttons with date presets, underline scope tabs with counts, "⋯"
  row menus, first column links to the record, pagination bar with gaps inside the table
  card. Show: header actions (Edit + "⋯"), details card, panels with optional `tab:`
  (server-side `?tab=`), right-column cards via `sidebars`/`show_sidebars/2`, `title:`
  option. Forms: card field groups, 32 px inputs, inline errors and an error summary.
  Toast flashes, dashed empty states, error pages. New config `subtitle`, `environment`,
  `sign_out`; new theme callback `account/1` (replaces `header_right/1`); new components
  `tabs/1`, `count/1`, `account_footer/1`, `columns/1`; index option `description:`. JS:
  `AlkemistSearchShortcut` ("/" focuses search) replaces the filters toggle; dropdowns
  close on outside click and Escape. SkimSafe-specific pieces from the mockups (wordmark
  colour, masked personnummer, provider cards) are deliberately left to the host app.
- **Tailwind v4 + esbuild asset pipeline** (`mix assets.setup|build|deploy`, no Node):
  `assets/css/alkemist.css` (entry, `.ak-*` component layer) and
  `assets/css/alkemist-theme.css` (`--ak-*` design tokens with dark mode, exposed to
  Tailwind via `@theme inline`), `assets/js/alkemist.js` with `phx-hook`-shaped ES modules
  (`AlkemistRowLink`, `AlkemistBatchSelect`, `AlkemistFiltersToggle`, `AlkemistNestedForm`,
  `AlkemistPerPage`, `AlkemistTheme`) exported as `AlkemistHooks`. Prebuilt output is
  committed to `priv/static/assets/`; hosts serve it with `Plug.Static at: "/alkemist",
  from: :alkemist, only: ~w(assets)` (mode A) or compile it themselves via `@source
  "../../deps/alkemist/lib"` (mode B). Brunch, CoreUI, Bootstrap, jQuery, Font Awesome and
  the `alkemist-default-theme` dependency are gone.
- **Forms are components**: `Alkemist.Components.Form` (`field/1` dispatching on the field
  type, `input/1`, `checkbox_group/1` replacing phoenix_mtm, `nested_many/1` and
  `nested_one/1` on `Phoenix.Component.inputs_for` with a `<key>_drop[]` remove checkbox
  and a client-side `<template>` for new entries, `errors_summary/1`, `translate_error/1`).
  Theme callbacks `resource_form/1` and `form_field/1`. `form_partial` is now a function
  component (`{Module, :fun}` or a capture) and receives `form`, `action`, `form_method`,
  `form_fields`, `struct`, `paths`; the 2.x `{View, "template.html"}` tuples raise with a
  hint. Date and datetime inputs are native (`type="date"`, `datetime-local`); booleans
  submit a hidden `false` sentinel; per-field `component:` renders a custom input.
- **Index and show pages are components**: `Alkemist.ResourceHTML` (`index`, `show`)
  built from `Alkemist.Components.{Table, Value, Actions, Filters, Pagination, Show}` and
  rendered inside the root layout with `<Layouts.app>`. New theme callbacks `filters/1`,
  `filter_field/1`, `pagination/1`, `value/1`, `member_actions/1`, `row_class/2`. Cell
  values are **escaped by default** (`{:safe, _}` and `~H` pass through; per-column
  `format: fn value, row -> ... end`). Sortable headers carry `aria-sort`; rows keep a real
  link and are click-navigable via `AlkemistRowLink`; batch selection posts `batch_ids[]`
  to the action's route through a plain form. New assigns `paths`, `link_params`, `sort`,
  `filter_form`, `filters_expanded`, `current_path`, `page_title`, `otp_app`, `theme`.
  Default action icons are `hero-eye`, `hero-pencil-square`, `hero-trash`; `icon:` options
  must be Heroicons names. Ecto `:naive_datetime`/`:utc_datetime` columns are typed
  `:datetime` (native `datetime-local` filters) and `:decimal` columns `:number`.
- **Component foundation**: `Alkemist.HTML` (`use` in theme modules), `Alkemist.Paths`,
  `Alkemist.Components.{Icons, Core, Layout, Menu, Theme}`, `Alkemist.Layouts` (root
  template + `app/1` shell), `Alkemist.ErrorHTML`. Icons are the Heroicons Alkemist uses,
  inlined as SVG; other `hero-*` names render as classes for mode B hosts.
- **`Alkemist.Theme` behaviour**: hosts `use Alkemist.Theme` and override any of `app/1`,
  `head/1`, `brand/1`, `header_right/1`, `sidebar/1`, `aside/1`, `flash_group/1`; the
  rest delegate to `Alkemist.Theme.Default`. Configured with `theme:`; also `root_layout:`,
  `assets: [css:, js:]` and `home_path:` config keys.
- Test infrastructure: SQL-sandboxed `Alkemist.DataCase`/`Alkemist.ConnCase`, a test
  endpoint and router with nested routes, fixture schemas for `belongs_to`, `many_to_many`
  and `binary_id` primary keys, and migrations under `test/support/repo` (never packaged).
  `mix test` now creates and migrates the test database.
- GitHub Actions CI matrix (Elixir 1.16–1.19, Postgres 17) with format, credo, dialyzer and
  prebuilt-asset checks.

### Removed
- **Phoenix.View, EEx templates and the 2.x view modules** (`AlkemistView`,
  `Alkemist.LayoutView`, `Alkemist.FormView`, `Alkemist.SearchView`,
  `Alkemist.PaginationView`, `Alkemist.ViewHelpers`, `Alkemist.ErrorView`,
  `Alkemist.ErrorHelpers`, `use Alkemist, :view`) and the `views:`/`decorators:` config keys,
  which now raise with a pointer to `theme:`. `phoenix_html` is `~> 4.1`.
- **Flop.** The query layer is now Alkemist's own: `Alkemist.Query.{Parser, Field, Filter,
  Sort, Ecto, Page, Search, Paginate}` plus the behaviours `Alkemist.Query.SearchProvider`
  and `Alkemist.Query.PaginationProvider`. The request dialect (`q[field_op]`, `s=field+dir`,
  `page`, `per_page`, `scope`) is unchanged. `Search.searchq/2` and `sortq/2` remain as
  deprecated shims; `Search.run/2` became `run/3`.

### Changed
- **CSV export streams.** `Alkemist.Export.CSV.send_stream/4` reads rows with
  `Repo.stream` in chunks, preloads per chunk, encodes with NimbleCSV and sends a chunked
  response; exports of any size run in constant memory. Config `csv: [separator:
  :semicolon | :comma | :tab, bom:, filename:, max_rows:]`, per-column `export:` override,
  default filename `<table>-<date>.csv`, CRLF line endings (RFC 4180). `create_csv/2` and
  `Assign.csv_assigns/3` remain as deprecated in-memory helpers; `Assign.csv_query/3` is the
  new building block.
- **Configuration is validated** with NimbleOptions (Alkemist.Config.Schema) and memoised
  per OTP app in `:persistent_term`; unknown keys raise, the removed keys `web_interface`,
  `json_library`, `router_helpers`, `route_prefix` raise with a pointer, `repo` is
  required. `Alkemist.Config.validate!/1` for boot-time checks, `reset/1` after changing
  config at runtime (tests). `views`/`decorators` stay valid until the component rewrite.
- **Paths are derived from the host router** by the new `Alkemist.Routes`
  (`Phoenix.Router.routes/1` + `Phoenix.Param`), so `router_helpers` and `route_prefix`
  config are gone and the schema's table name no longer has to match the route name.
  Controllers may define `path_for/4` to take over. The sidebar menu is discovered at
  runtime from the router (`Alkemist.Menu`) via `__alkemist_menu__/0` that
  `use Alkemist.Controller` emits; `Alkemist.MenuRegistry` (compile-time Agent, empty in
  releases) is removed. Optional `menu_cache: true`.
- `Alkemist.Authorization` is a behaviour (`use Alkemist.Authorization`); the default
  provider is `Alkemist.Authorization.Permissive`. Only a literal `true` authorises, for every
  action. **`csv/3` (`:export`) and `render_form/3` now check authorization.** Denied requests
  go to the new `forbidden_redirect_to` config (`"/"`, `{Mod, :fun}` or `:render`) instead of
  a hardcoded `page_path(:dashboard)`.
- `load_resource/4` casts ids with the primary key's `Ecto.Type` (binary ids via
  `Ecto.UUID`); unknown or malformed ids answer 404 instead of raising. `show` honours a
  custom `repo:`; `do_delete`'s `error_callback` receives `(resource, reason)`.
- Declared the previously undeclared optional callbacks `member_actions/0`,
  `collection_actions/0`, `search_provider/0`, `pagination_provider/0`, `show_panels/2`,
  `export/2`, `resource_key/0`, `path_for/4` so `@impl true` works.
- Filter and sort field names are resolved against the schema **by string comparison**; no
  atoms are created from request input and unknown fields are ignored (logged at debug, key
  names only).
- Association filters (`<assoc>_assoc_<field>_<op>`) work for **every** association, not only
  the previously hardcoded `subscriber`/`subscription`. Cardinality-one associations use one
  named left join; has_many / many_to_many / has_through filters use a semi-join subquery so
  counts are never inflated. Sorting by a belongs_to column is supported.
- `start` / `end` operators now really mean "starts with" / "ends with"; LIKE metacharacters in
  values are escaped; `in` accepts lists or comma-separated values; a list sent with `eq`
  means membership; new `null` / `not_null` operators.
- Date-only values on datetime columns expand to half-open day intervals (`eq` covers the
  whole day, `lteq` is `< next day`). Values are cast with the column's `Ecto.Type`; values
  that do not cast are ignored instead of raising in the database.
- Pagination runs exactly one `COUNT(*)` and one page query; `per_page` is clamped to
  `pagination[:max_per_page]` (default 100) and `page` to the last page. The old behaviour
  of returning an **unpaginated** query on error is gone. New config
  `pagination: [default_per_page:, max_per_page:, per_page_options:, scope_counts:]` and
  `timezone:` (for date-only filters on `utc_datetime` columns).
- The default sort is `<primary key>+desc` instead of the hardcoded `id+desc`; counts use
  `COUNT(*)`, so schemas without an `id` column work.
- Search and pagination providers are resolved at call time from config (they were captured
  in module attributes at compile time). Providers receive `schema:`, `repo:`, `otp_app:` and
  `timezone:` in `opts`. Scope counts can be disabled with `scope_counts: false`.
- `mix.exs` uses `def cli` instead of the deprecated `preferred_cli_env`; `extra_applications`
  is just `[:logger]`.
- New `Alkemist.Naming` replaces `inflex` and `slugger`. The form param key
  (`%{"post" => ...}`) is now derived from the schema **module name** via
  `Phoenix.Naming.resource_name/1`, matching `Phoenix.HTML.Form`, instead of singularising
  the table name. Schemas whose module and table disagree get a different key; override with
  `resource_key/0` on the controller (coming in step 3).
- `Alkemist.Gettext` uses the `Gettext.Backend` API.
- Dependencies: dropped `inflex`, `slugger`, `atomic_map`, `inch_ex` and the git-only
  `phoenix_mtm` (its checkbox helper is vendored until the component rewrite); bumped
  `credo`, `ex_doc`, `excoveralls`; added `dialyxir` and `stream_data`. Phoenix requirement
  is `~> 1.7.11 or ~> 1.8.0`.

### Fixed
- Fixed deprecation warning for `map.field` notation without parentheses in `lib/alkemist/assign.ex:290` and `lib/alkemist/assign.ex:292`. Changed `resource.__struct__` to `resource.__struct__()` to comply with modern Elixir syntax requirements.
- Fixed "column does not exist" error when using `_ilike` and `_not_ilike` operator suffixes in search parameters. Added support for these operators in the regex patterns in `lib/alkemist/query/search.ex:205` and `lib/alkemist/query/search.ex:347`, and added the corresponding operator mappings to `map_turbo_operator_to_flop/1` function. (Note: the `not_*` variants are still misparsed by the greedy regex; fixed for good by the 3.0 query rewrite.)

### Status (for whoever picks this up)
- 2026-09-23: Steps 0–9 of the 3.0 plan implemented on branch `v3/tailwind` (nothing
  committed yet), then the default theme was re-done to the admin UI kit and the
  Subscribers list/detail artboards (generic parts only). 144 tests + 42 doctests green,
  zero compiler warnings, prebuilt assets rebuilt; index, show (both tabs), edit, new with
  errors and dark mode checked visually against the design. Still open: QA against a real
  SkimSafe host app (Trinity admin keeps its SkimSafe-specific theme module), commit, the
  `v3.0.0` tag.

## [2.0.7-rc1] - 2025-11-28

The last 2.x line (branch `flopi-feature`), never tagged. Replaced Turbo.Ecto with Flop
(keeping the request dialect), replaced `html_sanitize_ex` with Floki, added a pagination
module, `ilike`/`not_ilike` operators, association filters for `subscriber`/`subscription`
and error views; moved to Elixir 1.16 and Phoenix 1.8 dependencies while still rendering
with Phoenix.View.

## [1.0.1-rc2] - 2019-04-26

Last release on `master`: Phoenix 1.3/1.4, Turbo.Ecto search and pagination, Bootstrap 4 /
CoreUI 2 theme built with Brunch.
