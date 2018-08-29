defmodule Alkemist.MixProject do
  use Mix.Project

  @version "0.0.1-dev"

  def project do
    [
      app: :alkemist,
      version: @version,
      elixir: "~> 1.6",
      compilers: [:phoenix] ++ Mix.compilers(),
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
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        inch: :test
      ],
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [
        :phoenix,
        :logger,
        :inflex,
        :atomic_map,
        :rummage_ecto
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.3.3"},
      {:phoenix_ecto, "~> 3.2"},
      {:phoenix_html, "~> 2.10"},
      {:ecto, "~> 2.2"},
      {:inflex, "~> 1.10.0"},
      {:atomic_map, github: 'ruby2elixir/atomic_map'},
      {:csv, "~> 2.0"},
      {:rummage_ecto, "~> 1.2"},
      # Test and dev
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10.0", only: :test},
      {:ex_doc, "~> 0.18.0", only: :dev, runtime: false},
      {:inch_ex, "~> 1.0", only: [:dev, :test, :doc]},
      {:postgrex, ">=0.0.0", only: :test}
    ]
  end

  defp docs do
    [
      main: "Alkemist",
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "static"],
      maintainers: ["Philip Mannheimer", "Julia Will", "Benjamin Betzing"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/FLEWID-AB/alkemist"}
    ]
  end

  defp description do
    """
    Provides some helper methods to build manager and admin applications quicker
    """
  end
end
