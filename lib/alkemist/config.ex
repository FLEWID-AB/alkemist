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
        field_value: {MyApp.IndexView, :field_string_value},
        row_class: {MyApp.IndexView, :row_decorator}
      ]
  """

  @default_otp_app :alkemist
  @default_implementation Alkemist

  @defaults [
    repo: nil,
    web_interface: "Alkemist",
    title: "Alkemist",
    logo: false,
    router_helpers: Alkemist.Router.Helpers,
    route_prefix: nil,
    authorization_provider: Alkemist.Authorization,
    json_library: Poison,
    query: [
      search: Alkemist.Query.Search,
      paginate: Alkemist.Query.Paginate
    ],
    views: [
      layout: {Alkemist.LayoutView, "app.html"},
      right_header: {Alkemist.LayoutView, "_right_header.html"},
      left_header: {Alkemist.LayoutView, "_left_header.html"},
      sidebar: {Alkemist.LayoutView, "_sidebar_navigation.html"},
      pagination: {AlkemistView, "_pagination.html"},
      filter: {AlkemistView, "_filter_view.html"},
      aside: {Alkemist.LayoutView, "_aside.html"},
      styles: {Alkemist.LayoutView, "_styles.html"},
      scripts: {Alkemist.LayoutView, "_scripts.html"}
    ],
    decorators: [
      filter: {Alkemist.SearchView, :filter_field_decorator},
      form: {Alkemist.FormView, :form_field_decorator},
      field_value: {AlkemistView, :field_string_value},
      member_actions: {AlkemistView, :member_actions_decorator},
      row_class: {Alkemist.View, :row_class_decorator}
    ]
  ]

  @doc """
  Returns a value from the configuration or the default value
  """
  def get(key, application \\ @default_otp_app, implementation \\ @default_implementation) do
    default = Keyword.get(@defaults, key)
    config(key, default, application, implementation)
  end

  @doc """
  Returns the configured Repo from alkemist configuration
  """
  def repo(application \\ @default_otp_app, implementation \\ @default_implementation) do
    get(:repo, application, implementation)
  end

  @doc """
  Returns the configured router helpers from alkemist configuration
  """
  def router_helpers(application \\ @default_otp_app, implementation \\ @default_implementation) do
    get(:router_helpers, application, implementation)
  end

  @doc """
  Returns the prefix or scope for the routes
  """
  def route_prefix(application \\ @default_otp_app, implementation \\ @default_implementation) do
    get(:route_prefix, application, implementation)
  end

  @doc """
  Returns the decorator for given areaa
  """
  def filter_decorator(application \\ @default_otp_app, implementation \\ @default_implementation) do
    decorators = get(:decorators, application, implementation)
    Keyword.get(decorators, :filter, @defaults[:decorators][:filter])
  end

  @doc """
  Returns the decorator for form fields
  """
  def form_field_decorator(application \\ @default_otp_app, implementation \\ @default_implementation) do
    decorators = get(:decorators, application, implementation)
    Keyword.get(decorators, :form, @defaults[:decorators][:form])
  end

  @doc """
  Returns the field value decorator to render the string value for given field type(s)
  """
  def field_value_decorator(application \\ @default_otp_app, implementation \\ @default_implementation) do
    decorators = get(:decorators, application, implementation)
    Keyword.get(decorators, :field_value, @defaults[:decorators][:field_value])
  end

  @doc """
  Returns the Member Actions decorator so it can be customized in implementations
  The method needs to have 2 implementations. One is for the header, the other one for the
  Actions column.
  `def member_actions(actions) do`
  `def member_actions(conn, actions, resource) do
  """
  def member_actions_decorator(application \\ @default_otp_app, implementation \\ @default_implementation) do
    decorators = get(:decorators, application, implementation)
    Keyword.get(decorators, :member_actions, @defaults[:decorators][:member_actions])
  end

  @doc """
  Returns the row class decorator, so classes can be overridden
  """
  def row_class_decorator(application \\ @default_otp_app, implementation \\ @default_implementation) do
    decorators = get(:decorators, application, implementation)
    Keyword.get(decorators, :row_class, @defaults[:decorators][:row_class])
  end

  @doc """
  Returns the configured authorization provider from alkemist configuration
  """
  def authorization_provider(application \\ @default_otp_app, implementation \\ @default_implementation) do
    get(:authorization_provider, application, implementation)
  end

  @doc """
  Returns the configured layout from alkemist configuration or the default
  """
  def layout(application \\ @default_otp_app, implementation \\ @default_implementation) do
    views = get(:views, application, implementation)
    Keyword.get(views, :layout, @defaults[:views][:layout])
  end

  @doc """
  Returns the search hook to use by default
  """
  def search_provider(application \\ @default_otp_app, implementation \\ @default_implementation) do
    query = get(:query, application, implementation)
    Keyword.get(query, :search, @defaults[:query][:search])
  end

  @doc """
  Returns the pagination provider to use by default
  """
  def pagination_provider(application \\ @default_otp_app, implementation \\ @default_implementation) do
    query = get(:query, application, implementation)
    Keyword.get(query, :paginate, @defaults[:query][:paginate])
  end

  @doc """
  Returns the json encoder to use by default
  """
  def json_provider(application \\ @default_otp_app, implementation \\ @default_implementation) do
    get(:json_library, application, implementation)
  end

  defp config(application, implementation) do
    Application.get_env(application, implementation, [])
  end

  defp config(key, default, application, implementation) do
    application
    |> config(implementation)
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
