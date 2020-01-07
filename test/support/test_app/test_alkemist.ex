defmodule TestAlkemist do
  @moduledoc false

  def controller do
    quote do
      use Phoenix.Controller, namespace: TestAlkemist

      import Plug.Conn
      import TestAlkemist.Gettext
      alias TestAlkemist.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "test/support/test_app/templates",
        namespace: TestAlkemist

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import TestAlkemist.ErrorHelpers
      import TestAlkemist.Gettext
      alias TestAlkemist.Router.Helpers, as: Routes
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
