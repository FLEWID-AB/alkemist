defmodule Alkemist.Factory do
  alias TestAlkemist.{Post, Category, Repo}

  def build(:post) do
    %Post{
      title: Faker.Lorem.sentence(1..4),
      body: Faker.Lorem.paragraph(),
      published: true
    }
  end

  def build(:post_with_category) do
    :post
    |> build()
    |> Map.put(:category, build(:category))
  end

  def build(:category) do
    %Category{
      name: Faker.Lorem.word()
    }
  end

  def build(factory, attributes \\ []) do
    factory
    |> build()
    |> struct(attributes)
  end

  def build_list(count, factory, attributes \\ []) do
    Enum.reduce(1..count, [], fn _ct, acc ->
      acc ++ [build(factory, attributes)]
    end)
  end

  def insert!(factory, attributes \\ []) do
    Repo.insert!(build(factory, attributes))
  end

  def insert_list!(count, factory, attributes \\ []) do
    Enum.reduce(1..count, [], fn _ct, acc ->
      acc ++ [insert!(factory, attributes)]
    end)
  end
end
