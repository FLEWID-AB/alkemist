defmodule Alkemist.Components.Theme do
  @moduledoc """
  Dispatches to the configured `Alkemist.Theme` module at runtime.

  Alkemist's own templates call `<Theme.brand ... />` etc.; this module looks up the theme
  from the `:theme` assign (per-controller override) or the `theme:` config of the page's
  `alkemist_app`, and calls the callback there. Because the theme module is resolved at
  render time, hosts can change it in config without recompiling Alkemist.
  """
  use Phoenix.Component

  for {name, 1} <- Alkemist.Theme.callbacks() do
    @doc "Calls `#{name}/1` on the active theme."
    def unquote(name)(assigns) do
      assigns = Map.put_new(assigns, :__theme_assigns__, %{theme: assigns[:theme]})
      theme(assigns).unquote(name)(assigns)
    end
  end

  @doc "CSS classes for a row from the active theme (`row_class/2`)."
  @spec row_class(atom(), module() | nil, struct(), String.t()) :: String.t() | list()
  def row_class(alkemist_app, theme, row, default) do
    theme(%{alkemist_app: alkemist_app, theme: theme}).row_class(row, default)
  end

  @doc "The theme module for the given page assigns."
  @spec theme(map()) :: module()
  def theme(assigns) do
    assigns[:theme] || Alkemist.Config.get(:theme, assigns[:alkemist_app] || :alkemist)
  end
end
