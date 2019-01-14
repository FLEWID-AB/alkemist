defmodule Alkemist.Config do
  @moduledoc """
  This module encapsulates all config.exs options

  ## Usage:

  ### config.exs:

    config :alkemist, Alkemist,
      # required - set your app's Ecto Repo
      repo: MyApp.Repo,

      # required - set your app's cache_folder, should be named the same as your Web Interface Module
      web_interface: "MyAppWeb",

      # required when using the auto generated code
      router_helpers: MyAppWeb.Router.Helpers,

      # set a prefix on the global level - this will be prepended to the auto-generated routes if it is set
      route_prefix: :admin,

      # Set a custom logo (optional), must be placed in the asset folder.
      logo: "logo.svg",

      # Set a custom title or brand name (optional)
      title: "MyApp",

      # implement a custom Authorization Provider (optional)
      authorization_provider: MyApp.Authorization,

      # custom implementations for search and pagination (optional)
      query: [
        search: Alkemist.Query.Search,
        paginate: Alkemist.Query.Paginate
      ],

      # use custom views (optional)
      views: [
        # use a custom layout view, default is {Alkemist.LayoutView, "app.html"}
        layout: {MyAppWeb.LayoutView, "app.html"},

        # custom view partial for the right header menu, default {Alkemist.LayoutView, "_right_header.html"}
        right_header: {MyAppWeb.SharedView, "header_right.html"},

        # custom view partial for the left header menu, default {Alkemist.LayoutView, "_left_header.html"}
        left_header: {MyAppWeb.SharedView, "header_left.html"}

        # custom view partial for the sidebar to render the left menu, default `{Alkemist.LayoutView, "_sidebar_navigation.html"}`
        sidebar: {MyAppWeb.SharedView, "sidebar.html"},

        # custom view partial for the right sidebar. By default it renders the filters
        aside: {MyAppWeb.SharedView, "aside.html"}

        # use a custom css
        styles: {MyApp.SharedView, "styles.html"}

        # use a custom js
        scripts: {MyApp.SharedView, "scripts.html"}
      ],

      # Render custom form templates for filter and new/edit forms
      decorators: [
        filter: {MyApp.SearchView, :filter_decorator},
        form: {MyApp.FormView, :form_field_decorator},
        # Custom display for values in the index and show actions
        field_value: {MyApp.IndexView, :field_string_value}
      ]
  """

  @defaults [
    repo: nil,
    web_interface: "Alkemist",
    title: "Alkemist",
    logo: false,
    router_helpers: Alkemist.Router.Helpers,
    route_prefix: nil,
    authorization_provider: Alkemist.Authorization,
    query: [
      search: Alkemist.Query.Search,
      paginate: Alkemist.Query.Paginate
    ],
    views: [
      layout: {Alkemist.LayoutView, "app.html"},
      right_header: {Alkemist.LayoutView, "_right_header.html"},
      left_header: {Alkemist.LayoutView, "_left_header.html"},
      sidebar: {Alkemist.LayoutView, "_sidebar_navigation.html"},
      filter: {AlkemistView, "_filter_view.html"},
      aside: {Alkemist.LayoutView, "_aside.html"},
      styles: {Alkemist.LayoutView, "_styles.html"},
      scripts: {Alkemist.LayoutView, "_scripts.html"}
    ],
    decorators: [
      filter: {Alkemist.SearchView, :filter_field_decorator},
      form: {Alkemist.FormView, :form_field_decorator},
      field_value: {AlkemistView, :field_string_value}
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
  Returns the prefix or scope for the routes
  """
  def route_prefix(application \\ :alkemist) do
    get(:route_prefix, application)
  end

  @doc """
  Returns the decorator for given areaa
  """
  def filter_decorator(application \\ :alkemist) do
    decorators = get(:decorators, application)
    Keyword.get(decorators, :filter, @defaults[:decorators][:filter])
  end

  @doc """
  Returns the decorator for form fields
  """
  def form_field_decorator(application \\ :alkemist) do
    decorators = get(:decorators, application)
    Keyword.get(decorators, :form, @defaults[:decorators][:form])
  end

  @doc """
  Returns the field value decorator to render the string value for given field type(s)
  """
  def field_value_decorator(application \\ :alkemist) do
    decorators = get(:decorators, application)
    Keyword.get(decorators, :field_value, @defaults[:decorators][:field_value])
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
