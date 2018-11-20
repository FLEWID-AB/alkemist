defmodule Alkemist do
  @moduledoc """
  Alkemist is an admin toolbox for Phoenix applications.
  It allows developers to build admin interfaces in a modular and flexible way
  by providing helper functions to render forms, show- and index pages for resources.

  """

  def view do
    quote do
      use Phoenix.View, root: "lib/alkemist/templates", namespace: Alkemist

      import Phoenix.Controller, only: [get_flash: 2, view_module: 1]
      use Phoenix.HTML
      import Alkemist.Router.Helpers
      import Alkemist.ViewHelpers
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
