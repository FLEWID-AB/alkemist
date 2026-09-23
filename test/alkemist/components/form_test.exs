defmodule Alkemist.FormComponentsTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest, only: [render_component: 2]
  import Phoenix.Component, only: [to_form: 2]

  alias Alkemist.Components.Form

  defp form(params \\ %{}), do: to_form(params, as: :post)

  defp field(key, opts, params \\ %{}) do
    render_component(&Form.field/1, form: form(params), field: {key, opts})
  end

  describe "field types" do
    test "text, textarea, number, date, datetime, password, hidden" do
      assert field(:title, %{type: :string}, %{"title" => "Hi"}) =~
               ~s(<input type="text" id="post_title" name="post[title]" value="Hi")

      assert field(:body, %{type: :text}) =~ ~s(<textarea id="post_body" name="post[body]")
      assert field(:views, %{type: :integer}) =~ ~s(type="number" id="post_views")
      assert field(:price, %{type: :number}) =~ ~s(step="any")
      assert field(:published_at, %{type: :date}) =~ ~s(type="date")
      assert field(:published_at, %{type: :datetime}) =~ ~s(type="datetime-local")
      html = field(:secret, %{type: :password}, %{"secret" => "x"})
      assert html =~ ~s(type="password")
      refute html =~ ~s(value="x")

      assert String.trim(field(:token, %{type: :hidden, value: "abc"})) ==
               ~s(<input type="hidden" id="post_token" name="post[token]" value="abc">)
    end

    test "boolean renders a checkbox with a false sentinel" do
      html = field(:published, %{type: :boolean}, %{"published" => "true"})
      assert html =~ ~s(<input type="hidden" name="post[published]" value="false">)
      assert html =~ ~s(type="checkbox" id="post_published" name="post[published]" value="true" checked)
    end

    test "select and multi select" do
      html = field(:category_id, %{type: :select, collection: [{"News", 1}, {"Sport", 2}]}, %{"category_id" => "2"})
      assert html =~ ~s(<select id="post_category_id" name="post[category_id]")
      assert html =~ ~s(<option value="">Choose...</option>)
      assert html =~ ~s(<option selected value="2">Sport</option>)

      html = field(:tag_ids, %{type: :select_multi, collection: [{"a", 1}, {"b", 2}]}, %{"tag_ids" => ["1"]})
      assert html =~ ~s(name="post[tag_ids][]" class="ak-input" multiple)
      assert html =~ ~s(<option selected value="1">a</option>)
    end

    test "many_to_many renders a checkbox group with an empty sentinel" do
      html = field(:tags, %{type: :many_to_many, collection: [{"elixir", 1}, {"erlang", 2}]}, %{"tags" => ["2"]})
      assert html =~ ~s(<input type="hidden" name="post[tags][]" value="">)
      assert html =~ ~s(id="post_tags_2" name="post[tags][]" value="2" checked)
      assert html =~ ~s(id="post_tags_1" name="post[tags][]" value="1" class)
    end

    test "passthrough options and required marker" do
      html = field(:title, %{type: :string, required: true, placeholder: "Title here", maxlength: 10})
      assert html =~ ~s(placeholder="Title here")
      assert html =~ ~s(maxlength="10")
      assert html =~ ~s(required)
      assert html =~ "ak-required"
    end

    test "a custom component takes over" do
      html =
        field(:color, %{
          type: :string,
          component: fn assigns -> Phoenix.HTML.raw(~s(<input type="color" name="#{assigns.field.name}">)) end
        })

      assert html == ~s(<input type="color" name="post[color]">)
    end
  end

  describe "errors" do
    test "inputs show translated errors from a submitted changeset" do
      changeset = %Alkemist.Post{} |> Alkemist.Post.changeset(%{"title" => ""}) |> Map.put(:action, :insert)
      form = to_form(changeset, as: :post)
      html = render_component(&Form.field/1, form: form, field: {:title, %{type: :string}})
      assert html =~ ~s(aria-invalid="true")
      assert html =~ "can&#39;t be blank"
      assert render_component(&Form.errors_summary/1, form: form) =~ "Title can&#39;t be blank"
    end

    test "no errors are shown for an untouched form" do
      changeset = Alkemist.Post.changeset(%Alkemist.Post{}, %{})
      html = render_component(&Form.field/1, form: to_form(changeset, as: :post), field: {:title, %{type: :string}})
      refute html =~ "aria-invalid"
    end
  end

  describe "nested forms" do
    test "has_many renders existing entries, drop checkboxes and a template" do
      category = %Alkemist.Category{id: 1, name: "News", posts: [%Alkemist.Post{id: 5, title: "Old"}]}
      form = to_form(Alkemist.Category.changeset(category, %{}), as: :category)

      html =
        render_component(&Form.field/1,
          form: form,
          field: {:posts, %{type: :has_many, fields: [{:title, %{type: :string}}]}}
        )

      assert html =~ ~s(phx-hook="AlkemistNestedForm")
      assert html =~ ~s(name="category[posts][0][title]" value="Old")
      assert html =~ ~s(name="category[posts][0][id]")
      assert html =~ ~s(name="category[posts_drop][]" value="0")
      assert html =~ ~s(<template data-nested-template>)
      assert html =~ ~s(name="category[posts][__INDEX__][title]")
      assert html =~ "data-nested-add"
    end

    test "has_one shows an Add button when empty" do
      form = to_form(%{}, as: :post)
      html = render_component(&Form.field/1, form: form, field: {:meta, %{type: :map, fields: [:note]}})
      assert html =~ ~s(name="post[meta][note]")
      assert html =~ "data-nested-add"
    end
  end
end
