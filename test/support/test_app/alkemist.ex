defmodule TestAlkemist.Alkemist do
  use Alkemist,
    otp_app: :alkemist,
    repo: TestAlkemist.Repo,
    router_helpers: TestAlkemist.Router.Helpers
end
