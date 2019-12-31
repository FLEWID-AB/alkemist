defmodule Alkemist.Assign.FormTest do
  use Alkemist.DataCase, async: true

  alias Alkemist.{Post, Assign.Form}
  doctest Form

  describe "assigns" do
    test "it creates default assigns without options" do
      assigns = Form.assigns(Post)
      assert length(assigns[:form_fields]) == 1
      assert is_map(Enum.at(assigns[:form_fields], 0))
      assert %Ecto.Changeset{} = assigns[:changeset]
    end

    test "it preloads associations in changeset" do
      category = Alkemist.Fixtures.category_fixture()
      post = Alkemist.Fixtures.post_fixture(%{category_id: category.id})
      assigns = Form.assigns(Post, [preload: [:category], changeset: Post.changeset(post, %{})])
      assert %{data: data} = assigns[:changeset]
      assert data.category
      assert data.category.id == category.id
    end

    test "it creates multiple field groups" do
      opts = [
        fields: [
          %{title: "Details", fields: [:title, :body]},
          %{title: "Meta", fields: [:published]}
        ]
      ]
      assigns = Form.assigns(Post, opts)
      assert length(assigns[:form_fields]) == 2
    end
  end

  describe "default_opts" do
    test "it creates default options" do
      assert opts = Form.default_opts([], Post)

      assert %Ecto.Changeset{data: %Post{}} = opts[:changeset]
      assert opts[:fields] == Alkemist.Utils.editable_fields(Post)
      assert opts[:form_partial]
    end

    test "it adds form_partial" do
      partial = {AlkemistView, "custom_form.html"}
      opts = Form.default_opts([form_partial: partial], Post)

      refute opts[:fields]
      assert opts[:form_partial] == partial
    end

    test "it merges assigns when using form partial" do
      partial = {AlkemistView, "form.html", foo: "bar"}
      opts = [
        form_partial: partial,
        assigns: [bar: "foo"]
      ]

      opts = Form.default_opts(opts, Post)
      assert opts[:assigns][:foo] == "bar"
      assert opts[:assigns][:bar] == "foo"
    end
  end
end
