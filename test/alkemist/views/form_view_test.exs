defmodule Alkemist.FormViewTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest, only: [build_conn: 0]
  alias Alkemist.FormView
  alias Alkemist.TestImplementation, as: Implementation

  describe "form_field" do
    test "it renders hidden fields" do
      form = Phoenix.HTML.Form.form_for(build_conn(), "/", fn form ->
        FormView.form_field(form, {:name, %{type: :hidden, value: "test"}}, Implementation)
      end) |> Phoenix.HTML.safe_to_string()

      assert form =~ "type=\"hidden\""
      assert form =~ "name=\"name\""
      assert form =~ "value=\"test\""
    end

    test "it renders checkboxes for boolean fields" do
      form = Phoenix.HTML.Form.form_for(build_conn(), "/", fn form ->
        FormView.form_field(form, {:check, %{type: :boolean}}, Implementation)
      end) |> Phoenix.HTML.safe_to_string()

      assert form =~ "type=\"checkbox\""
      assert form =~ "name=\"check\""
    end

    test "it renders has many fields and adds empty form template" do
      changeset = Alkemist.Category.changeset(%Alkemist.Category{}, %{})
      field = {:posts, %{
        type: :has_many,
        fields: [
          {:title, %{type: :string}}
        ]
      }}
      form = Phoenix.HTML.Form.form_for(changeset, "/", fn form ->
        FormView.form_field(form, field, Implementation)
      end) |> Phoenix.HTML.safe_to_string()

      assert form =~ "data-template"
      assert form =~ "alkemist_hm--container"
    end

    test "it renders text fields" do
      form = Phoenix.HTML.Form.form_for(build_conn(), "/", fn form ->
        FormView.form_field(form, {:name, %{type: :string}}, Implementation)
      end) |> Phoenix.HTML.safe_to_string()
      assert form =~ "type=\"text\""
      assert form =~ "name=\"name\""
    end

    test "it renders number fields" do
      form = Phoenix.HTML.Form.form_for(build_conn(), "/", fn form ->
        FormView.form_field(form, {:value, %{type: :number}}, Implementation)
      end) |> Phoenix.HTML.safe_to_string()
      assert form =~ "type=\"number\""
      assert form =~ "name=\"value\""
    end

    test "it renders date fields" do
      form = Phoenix.HTML.Form.form_for(build_conn(), "/", fn form ->
        FormView.form_field(form, {:created_at, %{type: :date}}, Implementation)
      end) |> Phoenix.HTML.safe_to_string()
      assert form =~ "datepicker"
      assert form =~ "name=\"created_at\""
    end

    test "it renders password fields" do
      form = Phoenix.HTML.Form.form_for(build_conn(), "/", fn form ->
        FormView.form_field(form, {:pass, %{type: :password}}, Implementation)
      end) |> Phoenix.HTML.safe_to_string()
      assert form =~ "type=\"password\""
      assert form =~ "name=\"pass\""
    end

    test "it renders textareas" do
      form = Phoenix.HTML.Form.form_for(build_conn(), "/", fn form ->
        FormView.form_field(form, {:body, %{type: :text}}, Implementation)
      end) |> Phoenix.HTML.safe_to_string()
      assert form =~ "textarea"
    end

    test "it renders select fields" do
      form = Phoenix.HTML.Form.form_for(build_conn(), "/", fn form ->
        FormView.form_field(form, {:category_id, %{type: :select, collection: [{"Name", 2}]}}, Implementation)
      end) |> Phoenix.HTML.safe_to_string()
      assert form =~ "select"
      assert form =~ "<option"
      assert form =~ "value=\"2\""
    end

    test "it renders multiple select fields" do
      form = Phoenix.HTML.Form.form_for(build_conn(), "/", fn form ->
        FormView.form_field(form, {:ids, %{type: :select_multi, collection: ["Foo", "Bar"]}}, Implementation)
      end) |> Phoenix.HTML.safe_to_string()
      assert form =~ "multiple"
    end

    test "it renders many to many checkboxes" do
      form = Phoenix.HTML.Form.form_for(build_conn(), "/", fn form ->
        FormView.form_field(form, {:ids, %{type: :many_to_many, collection: [{"Foo", 1}]}}, Implementation)
      end) |> Phoenix.HTML.safe_to_string()
      assert form =~ "type=\"checkbox\""
    end
  end
end
