defmodule Alkemist.Repo.Migrations.CreateTestTables do
  @moduledoc "Tables backing the test fixtures in test/support/models. Test-only; not shipped."
  use Ecto.Migration

  def change do
    create table(:categories) do
      add(:name, :string)
      timestamps()
    end

    create table(:posts) do
      add(:title, :string)
      add(:body, :text)
      add(:published, :boolean, default: false, null: false)
      add(:views, :integer)
      add(:price, :decimal)
      add(:published_at, :naive_datetime)
      add(:category_id, references(:categories, on_delete: :nilify_all))
      timestamps()
    end

    create(index(:posts, [:category_id]))

    create table(:tags) do
      add(:name, :string)
      timestamps()
    end

    create table(:posts_tags, primary_key: false) do
      add(:post_id, references(:posts, on_delete: :delete_all), null: false)
      add(:tag_id, references(:tags, on_delete: :delete_all), null: false)
    end

    create(unique_index(:posts_tags, [:post_id, :tag_id]))

    create table(:uuid_items, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string)
      timestamps()
    end
  end
end
