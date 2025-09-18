defmodule Alkemist.LayoutView do
  use Phoenix.View,
    root: "lib/alkemist/templates",
    namespace: Alkemist

  import Phoenix.HTML
  import Phoenix.HTML.Link
  import Phoenix.HTML.Tag
  import Phoenix.HTML.Form
  import Phoenix.Controller, only: [get_flash: 2]
  import Alkemist.ViewHelpers

  # Add static_path function for asset serving
  def static_path(_conn, path) do
    # This would normally come from your router helpers
    # For now, return the path as-is since Alkemist serves its own assets
    path
  end
end
