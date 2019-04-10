defmodule Alkemist.Repo do
  use Ecto.Repo, Application.get_env(:alkemist, Alkemist.Repo)
end
