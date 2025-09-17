defmodule Alkemist.LayoutView do
  # Phoenix 1.8 template rendering
  use Phoenix.Template,
    root: "lib/alkemist/templates/layout",
    namespace: Alkemist

  import Phoenix.HTML
  import Phoenix.HTML.Link
  import Phoenix.HTML.Tag
  import Alkemist.ViewHelpers
end
