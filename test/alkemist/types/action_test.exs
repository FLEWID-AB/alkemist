defmodule Alkemist.Types.ActionTest do
  use ExUnit.Case, async: true

  alias Alkemist.Types.Action
  doctest Action

  describe "map" do
    test "it sets default options" do
      action = %Action{action: :delete, type: :member}

      assert %Action{
        action: :delete,
        type: :member,
        label: "Delete",
        link_opts: [
          method: :delete,
          data: [
            confirm: _
          ]
        ]
      } = Action.map(action)
    end

    test "it omits defaults when set" do
      action = %Action{action: :delete, type: :member, link_opts: [class: "foo"]}

      assert %Action{
        link_opts: [class: "foo"]
      } = Action.map(action)
    end

    test "it can be created from atom" do
      assert %Action{
        type: :member,
        action: :edit,
        label: "Edit"
      } = Action.map(:edit, :member)
    end

    test "it can have options" do
      assert %Action{
        label: "Custom Edit",
        type: :member,
        action: :edit
      } = Action.map({:edit, [label: "Custom Edit"]}, :member)
    end
  end

  describe "map_all" do
    test "it maps a list of actions" do
      actions = [{:edit, %{label: "Custom Edit"}}, :show]

      assert [
        %Action{
          label: "Custom Edit",
          action: :edit,
          type: :member
        },
        %Action{
          label: "Show",
          action: :show,
          type: :member
        }
      ] = Action.map_all(actions, :member)
    end
  end
end
