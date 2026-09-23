defmodule Alkemist.MixProject do
  use Mix.Project

  @version "3.0.0"

  def project do
    [
      app: :alkemist,
      version: @version,
      elixir: "~> 1.16",
      dialyzer: [plt_add_apps: [:mix, :ex_unit], ignore_warnings: ".dialyzer_ignore.exs"],
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: description(),
      package: package(),

      # Docs
      name: "Alkemist",
      docs: docs(),

      # Test
      test_coverage: [tool: ExCoveralls],
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases()
    ]
  end

  def cli do
    [preferred_envs: [coveralls: :test, "coveralls.detail": :test, "coveralls.html": :test]]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind alkemist", "esbuild alkemist"],
      "assets.deploy": ["tailwind alkemist --minify", "esbuild alkemist --minify"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.7.11 or ~> 1.8.0"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_html, "~> 4.1"},
      {:ecto_sql, "~> 3.11"},
      {:plug, "~> 1.15"},
      {:jason, "~> 1.4"},
      {:gettext, "~> 0.26 or ~> 1.0"},
      {:nimble_csv, "~> 1.2"},
      {:nimble_options, "~> 1.1"},
      {:floki, "~> 0.38"},
      {:phoenix_live_view, "~> 1.0"},
      {:tailwind, "~> 0.5", runtime: Mix.env() == :dev},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      # Dev and test
      {:postgrex, ">= 0.0.0", only: :test},
      {:stream_data, "~> 1.1", only: [:dev, :test]},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "guides/upgrading_to_3_0.md",
        "guides/configuration.md",
        "guides/query_dialect.md",
        "guides/theming.md"
      ],
      groups_for_extras: [Guides: ~r/guides\/.*/],
      groups_for_modules: [
        "Controllers and routing": [
          Alkemist.Controller,
          Alkemist.Router,
          Alkemist.Routes,
          Alkemist.Paths,
          Alkemist.Menu,
          Alkemist.Assign
        ],
        Configuration: [
          Alkemist.Config,
          Alkemist.Authorization,
          Alkemist.Authorization.Permissive,
          Alkemist.Naming,
          Alkemist.Schema
        ],
        Theming: [
          Alkemist.Theme,
          Alkemist.Theme.Default,
          Alkemist.HTML,
          Alkemist.Layouts,
          Alkemist.ResourceHTML,
          Alkemist.ErrorHTML
        ],
        Components: ~r/Alkemist\.Components\..*/,
        Query: ~r/Alkemist\.Query.*/,
        Export: [Alkemist.Export.CSV]
      ]
    ]
  end

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "priv/static",
        "priv/templates",
        "assets/css",
        "assets/js",
        "guides"
      ],
      maintainers: ["Philip Mannheimer", "Julia Will", "Benjamin Betzing"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/FLEWID-AB/alkemist"}
    ]
  end

  defp description do
    """
    Admin interfaces for Phoenix from thin controllers: filterable, sortable, paginated
    index tables, show pages, forms with nested associations, CSV export and a sidebar menu,
    rendered with Phoenix components and Tailwind.
    """
  end
end
