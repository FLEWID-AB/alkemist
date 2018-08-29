defmodule Alkemist.ViewHelpers do
  @moduledoc """
  Provides helpers for the CRUD views and templates
  """
  import Phoenix.HTML.Link
  import Phoenix.HTML
  import Phoenix.HTML.Tag
  alias Alkemist.{Utils}
  @helpers Alkemist.Config.router_helpers()

  @doc """
  Returns if a list has any entries
  """
  def any?(list), do: Enum.empty?(list) === false

  @doc """
  Create an action link
  Params:
    * label - Plain text or html label to name the link
    * conn - the connection
    * action - atom, action to be called (controller method)
    * resource - Can be either a Module or a struct (Db.User or %Db.User{})
    * opts - options for the link (class, title, data-methods)
  """
  def action_link(label, conn, action, resource, opts \\ []) do
    if Alkemist.Config.authorization_provider().authorize_action(resource, conn, action) do
      opts =
        opts
        |> Keyword.put_new(:to, resource_action_path(conn, resource, action))

      wrap = opts[:wrap]
      opts = Keyword.delete(opts, :wrap)
      link = link(raw(label), opts)

      case wrap do
        nil ->
          link

        wrap ->
          {tag, opts} =
            if is_atom(wrap) do
              {wrap, []}
            else
              wrap
            end

          content_tag(tag, opts) do
            link
          end
      end
    else
      ""
    end
  end

  def resource_action_path(conn, resource, action) when is_map(resource) do
    struct = Utils.get_struct(resource)
    path = apply(@helpers, String.to_atom("#{struct}_path"), [conn, action, resource])
  end

  def resource_action_path(conn, resource, action) do
    struct = Utils.get_struct(resource)
    path = apply(@helpers, String.to_atom("#{struct}_path"), [conn, action])
  end
end
