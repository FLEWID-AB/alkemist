defmodule Alkemist.Config do
  @moduledoc """
  This module encapsulates all config.exs options

  ## Usage:

  ### config.exs:

    config :alkemist, Alkemist,
      # required - set your app's Ecto Repo
      repo: MyApp.Repo,

      # required when using the auto generated code
      router_helpers: MyAppWeb.Router.Helpers,

      # Set a custom title or brand name
      title: "MyApp",

      # implement a custom Authorization Provider
      authorization_provider: MyApp.Authorization,

      search_provider: MyApp.CustomSearch,

      # use custom views (optional)
      views: [
        # use a custom layout view, default is {Alkemist.LayoutView, "app.html"}
        layout: {MyAppWeb.LayoutView, "app.html"},

        # custom view partial for the right header menu, default {Alkemist.LayoutView, "_right_header.html"}
        right_header: {MyAppWeb.SharedView, "header_right.html"},

        # custom view partial for the left header menu, default {Alkemist.LayoutView, "_left_header.html"}
        left_header: {MyAppWeb.SharedView, "header_left.html"}
      ]
  """

  @defaults [
    repo: nil,
    title: "Alkemist",
    router_helpers: Alkemist.Router.Helpers,
    authorization_provider: Alkemist.Authorization,
    query: [
      search: Alkemist.Query.Search,
      paginate: Alkemist.Query.Paginate
    ],
    views: [
      layout: {Alkemist.LayoutView, "app.html"},
      right_header: {Alkemist.LayoutView, "_right_header.html"},
      left_header: {Alkemist.LayoutView, "_left_header.html"}
    ]
  ]

  @doc """
  Returns a value from the configuration or the default value
  """
  def get(key, application \\ :alkemist) do
    default = Keyword.get(@defaults, key)
    config(key, default, application)
  end

  @doc """
  Returns the configured Repo from alkemist configuration
  """
  def repo(application \\ :alkemist) do
    get(:repo, application)
  end

  @doc """
  Returns the configured router helpers from alkemist configuration
  """
  def router_helpers(application \\ :alkemist) do
    get(:router_helpers, application)
  end

  @doc """
  Returns the configured authorization provider from alkemist configuration
  """
  def authorization_provider(application \\ :alkemist) do
    get(:authorization_provider, application)
  end

  @doc """
  Returns the configured layout from alkemist configuration or the default
  """
  def layout(application \\ :alkemist) do
    views = get(:views, application)
    Keyword.get(views, :layout, @defaults[:views][:layout])
  end

  @doc """
  Returns the search hook to use by default
  """
  def search_provider(application \\ :alkemist) do
    query = get(:query, application)
    Keyword.get(query, :search, @defaults[:query][:search])
  end

  @doc """
  Returns the pagination provider to use by default
  """
  def pagination_provider(application \\ :alkemist) do
    query = get(:query, application)
    Keyword.get(query, :paginate, @defaults[:query][:paginate])
  end

  defp config(application) do
    Application.get_env(application, Alkemist, [])
  end

  defp config(key, default, application) do
    application
    |> config()
    |> Keyword.get(key, default)
    |> merge_list(default)
    |> resolve_config(default)
  end

  defp merge_list(config, default) when is_list(config) do
    Keyword.merge(default, config)
  end

  defp merge_list(config, _default), do: config

  defp resolve_config(value, _default), do: value
end
