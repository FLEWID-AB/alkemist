defmodule Alkemist.Fixtures do
  alias Alkemist.{Post, Category, Repo}

  def post_fixture(params \\ %{}) do
    defaults = %{
      title: Faker.Lorem.sentence(1..4),
      body: Faker.Lorem.paragraph(),
      published: true
    }

    %Post{}
    |> Post.changeset(Map.merge(defaults, params))
    |> Repo.insert!()
  end

  def category_fixture(params \\ %{}) do
    defaults = %{
      name: Faker.Lorem.word()
    }

    %Category{}
    |> Category.changeset(Map.merge(defaults, params))
    |> Repo.insert!()
  end
end
