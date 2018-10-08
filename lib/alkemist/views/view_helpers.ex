defmodule Alkemist.ViewHelpers do
  @moduledoc """
  Provides helpers for the CRUD views and templates
  """
  import Phoenix.HTML.Link
  import Phoenix.HTML
  import Phoenix.HTML.Tag
  alias Alkemist.{Utils}

  @doc """
  Returns if a list has any entries
  """
  def any?(list), do: Enum.empty?(list) === false

  @doc """
  Returns the current user if it is provided in the authorization provider
  """
  def current_user(conn) do
    Alkemist.Config.authorization_provider().current_user(conn)
  end

  @doc """
  Returns the current user's name if it is provided in the authorization provider
  """
  def current_user_name(conn) do
    Alkemist.Config.authorization_provider().current_user_name(conn)
  end

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
      # use exsisting :to option if available
      unless Keyword.has_key?(opts, :to), do: opts = Keyword.put_new(opts, :to, resource_action_path(conn, resource, action))

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

  def get_default_link_params(conn) do
    conn.params
    |> Alkemist.Utils.clean_params()
    |> Map.to_list()
    |> Enum.reduce([], fn {k, v}, acc ->
      case k do
        a when a in ["scope", "q", "s", "per_page"] ->
          if v in [nil, %{}, [], ""] do
            acc
          else
            acc ++ [{k, v}]
          end

        _ ->
          acc
      end
    end)
    |> Enum.into(%{})
  end

  def resource_action_path(conn, resource, action, params \\ %{})

  def resource_action_path(conn, resource, action, params) when is_map(resource) do
    helper = Utils.default_resource_helper(resource)

    apply(Alkemist.Config.router_helpers(), helper, [
      conn,
      action,
      resource,
      params
    ])
  end

  def resource_action_path(conn, resource, action, params) do
    helper = Utils.default_resource_helper(resource)

    apply(Alkemist.Config.router_helpers(), helper, [
      conn,
      action,
      params
    ])
  end
end
