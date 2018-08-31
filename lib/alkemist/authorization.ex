defmodule Alkemist.Authorization do
  @moduledoc """
  A fallback Authentication and authorization provider.
  Use this file as a template to implement your own authentication methods.

  Then in your config.exs specify the Authorization Provider:

    config :alkemist, Alkemist,
      authorization_provider: MyApp.Authorization
  """

  @doc """
  Authorizes a controller action for a resource.

  ## Usage:

    iex> Alkemist.Authorization.authorize_action(Alkemist.Post, conn, :delete)
    true

    iex> Alkemist.Authorization.authorize_action(%Alkemist.Post{user_id: 1}, conn, :update)
    true
  """
  def authorize_action(_resource, _conn, _action) do
    true
  end

  @doc """
  Returns the current user.
  When you implement this action, you can return your currently logged in user from the
  conn.assigns

  ## Example:

  ```elixir
  def current_user(conn), do: conn.assigns.current_user
  ```
  """
  def current_user(_conn), do: nil

  @doc """
  Returns the display name for the current user from the conn

  ## Example:

  ```elixir
  def current_user_name(_conn), do: current_user(conn).username
  ```
  """
  def current_user_name(_conn), do: nil
end
