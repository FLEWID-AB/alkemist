defmodule Manager.Config do
  @moduledoc """
  This module encapsulates all config.exs options

  ## Usage:

  ### config.exs:

    config :manager, Manager,
      repo: MyApp.Repo
  """

  def repo(application \\ :manager) do
    config(:repo, nil, application)
  end

  def router_helpers(application \\ :manager) do
    config(:router_helpers, Manager.Router.Helpers, application)
  end

  defp config(application) do
    Application.get_env(application, Manager, [])
  end

  defp config(key, default, application) do
    config(application)
    |> Keyword.get(key, default)
    |> resolve_config(default)
  end

  defp resolve_config(value, _default), do: value
end
