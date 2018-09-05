defmodule Alkemist.LayoutView do
  use Alkemist, :view

  @doc """
  Returns the registered menu items for the sidebar
  """
  def menu_items do
    Alkemist.MenuRegistry.menu_items()
  end

  @doc """
  Returns the view module and template for the right header menu if it is set in the configuration
  """
  def right_header_view do
    Keyword.get(Alkemist.Config.get(:views), :right_header)
  end

  @doc """
  Returns the view module and template for the left header (brand) if it is set in the configuration
  """
  def left_header_view do
    Keyword.get(Alkemist.Config.get(:views), :left_header)
  end

  @doc """
  Returns the view module and template for the sidebar see `Alkemist.Config`
  """
  def sidebar_view do
    Keyword.get(Alkemist.Config.get(:views), :sidebar)
  end

  @doc """
  Returns the view module and template for the aside menu. See `Alkemist.Config`
  """
  def aside_view do
    Keyword.get(Alkemist.Config.get(:views), :aside)
  end

  @doc """
  Returns the scripts view
  """
  def scripts_view do
    Keyword.get(Alkemist.Config.get(:views), :scripts)
  end

  @doc """
  Returns the styles view
  """
  def styles_view do
    Keyword.get(Alkemist.Config.get(:views), :styles)
  end

  @doc """
  Returns the site title to display in the title and in the header
  """
  def site_title do
    Alkemist.Config.get(:title)
  end
end
