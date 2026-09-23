defmodule <%= controller_name %>Controller do
  use <%= web_module %>, :controller

  # The Ecto schema must be set before `use Alkemist.Controller`.
  @resource <%= model %>
  use Alkemist.Controller, otp_app: :<%= otp_app %>

  # menu "<%= plural |> String.capitalize() %>", parent: "Admin"

  def index(conn, params), do: render_index(conn, params)
  def show(conn, %{"id" => id}), do: render_show(conn, id)
  def new(conn, _params), do: render_new(conn)
  def edit(conn, %{"id" => id}), do: render_edit(conn, id)
  def create(conn, %{"<%= singular %>" => params}), do: do_create(conn, params)
  def update(conn, %{"id" => id, "<%= singular %>" => params}), do: do_update(conn, id, params)
  def delete(conn, %{"id" => id}), do: do_delete(conn, id)
  def export(conn, params), do: csv(conn, params)

  # Customise columns, filters, scopes or fields by implementing the optional callbacks:
  #
  # @impl true
  # def columns(_conn), do: [:id, :name, {"Created", fn r -> r.inserted_at end}]
  #
  # @impl true
  # def filters(_conn), do: [name: %{primary: true}, inserted_at: %{type: :datetime}]
end
