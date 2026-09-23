defmodule Alkemist.HTML do
  @moduledoc """
  `use Alkemist.HTML` in a module that renders Alkemist pages or theme components. It
  brings in `Phoenix.Component`, `Phoenix.HTML` and every Alkemist component module, the
  same way `MyAppWeb.html/0` does in a Phoenix 1.8 app.

      defmodule MyAppWeb.AlkemistTheme do
        use Alkemist.Theme   # includes `use Alkemist.HTML`

        def brand(assigns) do
          ~H|<a href="/" class="ak-brand"><img src="/images/logo.svg" alt="MyApp" /></a>|
        end
      end
  """

  defmacro __using__(_opts) do
    quote do
      use Phoenix.Component
      use Gettext, backend: Alkemist.Gettext
      import Phoenix.HTML, only: [raw: 1]

      import Alkemist.Components.Icons
      import Alkemist.Components.Core
      import Alkemist.Components.Layout
      import Alkemist.Components.Menu

      alias Alkemist.Components.Theme
      alias Alkemist.Layouts
      alias Alkemist.Paths
    end
  end
end
