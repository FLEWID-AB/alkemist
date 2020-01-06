defmodule TestAlkemist.Application do
  use Application

  def start(_type, _args) do
    children = [
      TestAlkemist.Repo,
      TestAlkemist.Endpoint
    ]

    opts = [strategy: :one_for_one, name: TestAlkemist.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    TestAlkemist.Endpoint.config_change(changed, removed)
  end
end
