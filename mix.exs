defmodule Alkemist.MixProject do
  use Mix.Project

  @version "1.0.1-rc2"

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
        :turbo_ecto,
        :phoenix_mtm,
        :html_sanitize_ex,
        :slugger,
        :jason
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.3 or ~> 1.4"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 2.10"},
      {:ecto, "~> 3.0"},
      {:jason, "~> 1.1"},
      {:inflex, "~> 1.10.0"},
      {:csv, "~> 2.0"},
      {:turbo_ecto, "~> 0.4.3"},
      {:phoenix_mtm, "~> 1.0"},
      {:gettext, ">= 0.0.0"},
      {:html_sanitize_ex, "~> 1.3.0-rc3"},
      {:slugger, "~> 0.3"},
      # Test and dev
      {:plug_cowboy, "~> 2.0", only: [:test]},
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10.0", only: :test},
      {:ex_doc, "~> 0.18.0", only: :dev, runtime: false},
      {:inch_ex, "~> 1.0", only: [:dev, :test, :doc]},
      {:postgrex, ">=0.0.0", only: :test},
      {:faker, "~> 0.13.0", only: :test},
      {:wallaby, "~> 0.23.0", only: :test, runtime: false}
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
      files: ["lib", "mix.exs", "README.md", "priv"],
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
