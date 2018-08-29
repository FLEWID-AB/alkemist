defmodule Alkemist.Config do
  @moduledoc """
  This module encapsulates all config.exs options

  ## Usage:

  ### config.exs:

    config :alkemist, Alkemist,
      repo: MyApp.Repo
  """

  def repo(application \\ :alkemist) do
    config(:repo, nil, application)
  end

  def router_helpers(application \\ :alkemist) do
    config(:router_helpers, Alkemist.Router.Helpers, application)
  end

  def authorization_provider(application \\ :alkemist) do
    config(:authorization_provider, Alkemist.Authorization, application)
  end

  defp config(application) do
    Application.get_env(application, Alkemist, [])
  end

  defp config(key, default, application) do
    config(application)
    |> Keyword.get(key, default)
    |> resolve_config(default)
  end

  defp resolve_config(value, _default), do: value
end
