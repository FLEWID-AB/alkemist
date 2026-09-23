defmodule AlkemistTest.CategoryController do
  @moduledoc "Fixture controller with all CRUD actions, filters and scopes."
  use Phoenix.Controller, formats: [:html]
  import Ecto.Query, only: [where: 3]

  @resource Alkemist.Category
  use Alkemist.Controller

  menu("Categories", icon: "hero-folder")

  def index(conn, params), do: render_index(conn, params, description: "Every category, with its posts.")
  def show(conn, %{"id" => id}), do: render_show(conn, id, title: fn c -> c.name end)
  def new(conn, _params), do: render_new(conn, [])
  def edit(conn, %{"id" => id}), do: render_edit(conn, id, [])
  def create(conn, %{"category" => params}), do: do_create(conn, params, [])
  def update(conn, %{"id" => id, "category" => params}), do: do_update(conn, id, params, [])
  def delete(conn, %{"id" => id}), do: do_delete(conn, id, [])
  def export(conn, params), do: csv(conn, params, [])

  @impl true
  def preload, do: [:posts]

  @impl true
  def columns(_conn), do: [:id, :name, {"Posts", fn c -> length(c.posts) end}, :inserted_at]

  @impl true
  def filters(_conn), do: [name: %{primary: true}, inserted_at: %{type: :datetime}, id: %{type: :integer}]

  @impl true
  def scopes(_conn) do
    [
      {:all, [default: true]},
      {:with_posts, [],
       fn q -> where(q, [c], c.id in subquery(Ecto.Query.select(Alkemist.Post, [p], p.category_id))) end}
    ]
  end

  @impl true
  def show_panels(_conn, category) do
    [
      {"Notes", content: "Plain notes <b>escaped</b>"},
      {"Posts", tab: "Posts", count: length(category.posts), content: Enum.map_join(category.posts, ", ", & &1.title)}
    ]
  end

  @impl true
  def show_sidebars(_conn, category), do: [{"Summary", content: "#{length(category.posts)} posts"}]

  @impl true
  def fields(_conn, _resource),
    do: [
      :name,
      {:posts,
       %{type: :has_many, fields: [{:title, %{type: :string, required: true}}, {:published, %{type: :boolean}}]}}
    ]
end
