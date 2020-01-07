defmodule TestAlkemist.Alkemist do
  use Alkemist,
    otp_app: :alkemist,
    repo: TestAlkemist.Repo,
    router_helpers: TestAlkemist.Router.Helpers


  def current_user(conn), do: Map.get(conn.assigns, :current_user)

  def current_user_name(conn) do
    case current_user(conn) do
      nil -> ""
      user -> user.username
    end
  end

  def authorize_action(conn, _resource, _action) do
    case current_user(conn) do
      %{role: :admin} -> true

      _ -> false
    end
  end
end
