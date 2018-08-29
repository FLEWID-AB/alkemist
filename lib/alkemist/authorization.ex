defmodule Alkemist.Authorization do
  def authorize_action(_resource, _conn, _action) do
    true
  end
end
