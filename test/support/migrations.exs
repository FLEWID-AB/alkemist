defmodule Alkemist.Migrations do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add(:name, :string)
    end

    create table(:posts) do
      add(:title, :string)
      add(:body, :text)
      add(:published, :boolean)
      add(:category_id, references(:categories, on_delete: :nilify_all))
      timestamps()
    end
  end
end
