# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

Alkemist is an Elixir library (Hex package `alkemist`, 3.0) that gives Phoenix apps admin
CRUD pages from thin controllers. It is consumed by SkimSafe's back-office apps. Branch
`v3/tailwind` holds the 3.0 rewrite; `flopi-feature` is the last 2.x line.

## Commands

- `docker compose up -d db` then `PG_PORT=1234 mix test` (creates and migrates
  `alkemist_test`; migrations live in `test/support/repo/migrations`, never shipped)
- `mix compile --warnings-as-errors`, `mix format`, `mix credo --strict`, `mix dialyzer`
- `mix assets.setup && mix assets.build` after changing anything under `assets/` or a HEEx
  template/component (Tailwind scans `lib/alkemist`); the output in `priv/static/assets` is
  committed and CI diffs it
- `mix docs` (guides in `guides/`), `mix hex.build`

## Architecture (3.0)

- `Alkemist.Controller` macros (`render_index/show/new/edit`, `do_create/update/delete`,
  `csv`, `menu`) call `Alkemist.Assign` to normalise options into assigns and render
  `Alkemist.ResourceHTML` inside the root layout `Alkemist.Layouts`.
- Query layer: `Alkemist.Query.{Parser, Field, Filter, Sort, Ecto, Paginate, Page}` parses
  the `q[field_op]`/`s=field+dir`/`page`/`per_page` dialect against the schema by name (no
  atoms from input) and builds Ecto queries; providers implement
  `Alkemist.Query.SearchProvider` / `PaginationProvider`. No Flop.
- Paths come from the host router at runtime (`Alkemist.Routes`, `Alkemist.Paths`); the
  sidebar from controllers' `__alkemist_menu__/0` (`Alkemist.Menu`).
- Look and feel: `Alkemist.Theme` behaviour (default `Alkemist.Theme.Default`), dispatched
  through `Alkemist.Components.Theme`; components in `Alkemist.Components.*`; tokens in
  `assets/css/alkemist-theme.css`; classes `.ak-*` in `assets/css/alkemist.css`.
- Config: `Alkemist.Config` validated by NimbleOptions (`Alkemist.Config.Schema`), per
  OTP app, memoised in `:persistent_term` (`Alkemist.Config.reset/1` in tests).
- Authorization: `Alkemist.Authorization` behaviour; CSV export streams via
  `Alkemist.Export.CSV`.

## Conventions

- Escape by default: values render through `Alkemist.Components.Value`; only `{:safe, _}`
  or `~H` pass through. Never add `raw/1` on data.
- Never `String.to_atom` on request input; resolve names against `__schema__/1`.
- Keep the request dialect backwards compatible; document changes in `CHANGELOG.md` and
  `guides/upgrading_to_3_0.md`.
- Theme callbacks may be called as plain functions from templates: use `Map.put_new`, not
  `assign_new/3`, when defaulting assigns there.
- Phoenix legacy layout/view defaults use the `_` key: set layouts, root layouts and views
  with the module/tuple form, not the `html:` keyword form.
- Tests: `Alkemist.DataCase` (sandbox) and `Alkemist.ConnCase` (test endpoint + router in
  `test/support`); component tests use `Phoenix.LiveViewTest.render_component/2`.
