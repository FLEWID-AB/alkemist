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
      # implement a custom Authorization Provider
      authorization_provider: MyApp.Authorization,
      # use a custom layout instead of the one from Alkemist
      layout: {MyAppWeb.LayoutView, "app.html"}
  """

  @doc """
  Returns the configured Repo from alkemist configuration
  """
  def repo(application \\ :alkemist) do
    config(:repo, nil, application)
  end

  @doc """
  Returns the configured router helpers from alkemist configuration
  """
  def router_helpers(application \\ :alkemist) do
    config(:router_helpers, Alkemist.Router.Helpers, application)
  end

  @doc """
  Returns the configured authorization provider from alkemist configuration
  """
  def authorization_provider(application \\ :alkemist) do
    config(:authorization_provider, Alkemist.Authorization, application)
  end

  @doc """
  Returns the configured layout from alkemist configuration or the default
  """
  def layout(application \\ :alkemist) do
    config(:layout, {Alkemist.LayoutView, "app.html"}, application)
  end

  defp config(application) do
    Application.get_env(application, Alkemist, [])
  end

  defp config(key, default, application) do
    application
    |> config()
    |> Keyword.get(key, default)
    |> resolve_config(default)
  end

  defp resolve_config(value, _default), do: value
end
