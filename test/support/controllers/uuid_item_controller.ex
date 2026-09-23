defmodule AlkemistTest.UuidItemController do
  @moduledoc "Fixture controller for a schema with a binary_id primary key."
  use Phoenix.Controller, formats: [:html]
  @resource Alkemist.UuidItem
  use Alkemist.Controller

  def index(conn, params), do: render_index(conn, params, [])
  def show(conn, %{"id" => id}), do: render_show(conn, id, [])
end
