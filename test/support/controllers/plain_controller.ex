defmodule AlkemistTest.PlainController do
  @moduledoc "A plain Phoenix controller that is not an Alkemist resource."
  use Phoenix.Controller

  def dashboard(conn, _params), do: text(conn, "dashboard")
end
