defmodule Alkemist.DataCase do
  @moduledoc """
  Test case for tests that touch the database. Each test runs inside an
  `Ecto.Adapters.SQL.Sandbox` transaction that is rolled back afterwards.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Alkemist.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Alkemist.DataCase
    end
  end

  setup tags do
    Alkemist.DataCase.setup_sandbox(tags)
    :ok
  end

  @doc "Checks out a sandbox connection; shared when the test is not async."
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Alkemist.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc "Inserts a category with the given attributes."
  def insert_category!(attrs \\ %{}) do
    %Alkemist.Category{}
    |> Alkemist.Category.changeset(Enum.into(attrs, %{name: "Category"}))
    |> Alkemist.Repo.insert!()
  end

  @doc "Inserts a post with the given attributes."
  def insert_post!(attrs \\ %{}) do
    %Alkemist.Post{}
    |> Alkemist.Post.changeset(Enum.into(attrs, %{title: "Post"}))
    |> Alkemist.Repo.insert!()
  end

  @doc "Inserts a tag with the given attributes."
  def insert_tag!(attrs \\ %{}) do
    %Alkemist.Tag{}
    |> Alkemist.Tag.changeset(Enum.into(attrs, %{name: "tag"}))
    |> Alkemist.Repo.insert!()
  end
end
