# Configuration

Alkemist reads `config :<otp_app>, Alkemist, [...]`, validated with NimbleOptions on first
use (call `Alkemist.Config.validate!(:my_app)` from `Application.start/2` to fail at boot).

```elixir
config :my_app, Alkemist,
  repo: MyApp.Repo,                                  # required
  title: "MY APP",
  subtitle: "Admin",                                 # small text next to the brand
  logo: "/images/logo.svg",                          # or false for the text brand
  environment: "Production",                         # shown in the sidebar footer
  sign_out: [path: "/logout", method: :delete],      # sign-out button in the footer
  home_path: "/admin",
  authorization_provider: MyAppWeb.AlkemistAuthorization,
  forbidden_redirect_to: "/admin",                   # or {Mod, :fun} or :render
  theme: MyAppWeb.AlkemistTheme,
  root_layout: {Alkemist.Layouts, :root},
  assets: [css: "/alkemist/assets/alkemist.css", js: "/alkemist/assets/alkemist.js"],
  timezone: "Europe/Stockholm",                      # date-only filters on utc_datetime columns
  menu_cache: true,
  query: [search: Alkemist.Query.Search, paginate: Alkemist.Query.Paginate],
  pagination: [default_per_page: 25, max_per_page: 200, per_page_options: [25, 50, 100, 200], scope_counts: true],
  csv: [separator: :semicolon, bom: true, filename: "export.csv", max_rows: 500]
```

Every key is documented in `Alkemist.Config`. Controllers pick the app with
`use Alkemist.Controller, otp_app: :my_app`; several apps in an umbrella can each carry
their own block.
