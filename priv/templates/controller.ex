defmodule <%= controller_name %>Controller do
  use <%= web_module %>, :controller
  @resource <%= model %>
  use Alkemist.Controller

  def index(conn, params) do
    render_index(conn, params)
  end

  def show(conn, %{"id" => id}) do
    render_show(conn, id)
  end

  def new(conn, _params) do
    render_new(conn)
  end

  def edit(conn, %{"id" => id}) do
    render_edit(conn, id)
  end

  def create(conn, %{"<%= singular %>" => <%= singular %>_params}) do
    do_create(conn, <%= singular %>_params)
  end

  def update(conn, %{"id" => id, "<%= singular %>" => <%= singular %>_params}) do
    do_update(conn, id, <%= singular %>_params)
  end

  def delete(conn, %{"id" => id}) do
    do_delete(conn, id)
  end

  def export(conn, params) do
    csv(conn, params)
  end
end
