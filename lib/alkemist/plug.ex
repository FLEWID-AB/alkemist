defmodule Alkemist.Plug do
  @moduledoc """
  A simple plug that is used in controllers to provide private alkemist information in the `conn`
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    conn
    |> put_private(:alkemist_implementation, Keyword.get(opts, :implementation))
    |> put_private(:alkemist_resource, Keyword.get(opts, :resource))
  end

end
