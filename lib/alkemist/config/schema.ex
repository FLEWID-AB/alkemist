defmodule Alkemist.Config.Schema do
  @moduledoc false

  @schema [
    repo: [type: :atom, required: true, doc: "The `Ecto.Repo` used for every query and mutation."],
    title: [
      type: :string,
      default: "Alkemist",
      doc: "Brand name shown at the top of the sidebar and in `<title>`."
    ],
    subtitle: [type: {:or, [:string, nil]}, default: nil, doc: "Small text next to the brand name, e.g. `\"Admin\"`."],
    environment: [
      type: {:or, [:string, nil]},
      default: nil,
      doc: "Environment label in the sidebar footer, e.g. `\"Production\"`."
    ],
    sign_out: [
      type: {:or, [:keyword_list, nil]},
      default: nil,
      doc: "Sign-out link in the sidebar footer: `[path: \"/logout\", method: :delete]`."
    ],
    logo: [
      type: {:or, [:boolean, :string]},
      default: false,
      doc: "Path of a logo image served by the host app, or `false`."
    ],
    authorization_provider: [
      type: :atom,
      default: Alkemist.Authorization.Permissive,
      doc: "Module implementing `Alkemist.Authorization`."
    ],
    forbidden_redirect_to: [
      type: {:or, [:string, {:tuple, [:atom, :atom]}, {:in, [:render]}]},
      default: "/",
      doc: "Where denied requests go: a path, `{Module, :fun}` receiving the conn, or `:render` to answer 403."
    ],
    timezone: [
      type: :string,
      default: "Etc/UTC",
      doc: "Time zone for date-only filters on `utc_datetime` columns."
    ],
    menu_cache: [type: :boolean, default: false, doc: "Memoise the sidebar menu per router."],
    home_path: [type: :string, default: "/", doc: "Where the brand link and error pages point."],
    theme: [type: :atom, default: Alkemist.Theme.Default, doc: "Module implementing `Alkemist.Theme`."],
    root_layout: [
      type: {:tuple, [:atom, :atom]},
      default: {Alkemist.Layouts, :root},
      doc: "The `<html>` wrapper, `{module, template}`."
    ],
    assets: [
      type: :keyword_list,
      default: [],
      doc: "URLs of the stylesheet and script tags the default `head/1` emits; set both to `nil` to emit none.",
      keys: [
        css: [type: {:or, [:string, nil]}, default: "/alkemist/assets/alkemist.css"],
        js: [type: {:or, [:string, nil]}, default: "/alkemist/assets/alkemist.js"]
      ]
    ],
    query: [
      type: :keyword_list,
      default: [],
      doc: "Search and pagination provider modules.",
      keys: [
        search: [
          type: :atom,
          default: Alkemist.Query.Search,
          doc: "Implements `Alkemist.Query.SearchProvider`."
        ],
        paginate: [
          type: :atom,
          default: Alkemist.Query.Paginate,
          doc: "Implements `Alkemist.Query.PaginationProvider`."
        ]
      ]
    ],
    pagination: [
      type: :keyword_list,
      default: [],
      doc: "Pagination limits.",
      keys: [
        default_per_page: [type: :pos_integer, default: 10],
        max_per_page: [type: :pos_integer, default: 100],
        per_page_options: [type: {:list, :pos_integer}, default: [10, 25, 50, 100]],
        scope_counts: [
          type: :boolean,
          default: true,
          doc: "Show record counts next to index scopes."
        ]
      ]
    ],
    csv: [
      type: :keyword_list,
      default: [],
      doc: "CSV export settings, see `Alkemist.Export.CSV`.",
      keys: [
        separator: [type: {:in, [:semicolon, :comma, :tab]}, default: :semicolon],
        bom: [type: :boolean, default: false],
        filename: [type: {:or, [:string, {:fun, 1}, nil]}, default: nil],
        max_rows: [type: :pos_integer, default: 500]
      ]
    ]
  ]

  def schema, do: NimbleOptions.new!(@schema)
end
