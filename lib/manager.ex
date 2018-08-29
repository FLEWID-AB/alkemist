defmodule Manager do
  @moduledoc """
  Manager is an admin tool for Phoenix applications.
  TODO: write better documentation
  """

  def view do
    quote do
      use Phoenix.View, root: "lib/manager/templates", namespace: Manager

      import Phoenix.Controller, only: [get_flash: 2, view_module: 1]
      use Phoenix.HTML

      import Manager.ViewHelpers
    end
  end

  # TODO: move to config
  def authorization_provider,
    do: Application.get_env(:manager, :authorization_provider, Manager.Authorization)

  def repo, do: Application.get_env(:manager, :default_repo)

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
