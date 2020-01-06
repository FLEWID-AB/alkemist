defmodule TestAlkemist.Repo do
  use Ecto.Repo,
    otp_app: :alkemist,
    adapter: Ecto.Adapters.Postgres
end
