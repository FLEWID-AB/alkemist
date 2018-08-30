defmodule Alkemist.LayoutView do
  use Alkemist, :view

  @doc """
  Returns the registered menu items for the sidebar
  """
  def menu_items do
    Alkemist.MenuRegistry.menu_items()
  end
end
