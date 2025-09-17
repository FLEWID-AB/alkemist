defmodule Alkemist.MenuRegistry do
  @moduledoc """
  The MenuRegistry is used to store and retrieve menu items for the
  sidebar.

  You can define custom labels and options in your resource controllers.
  See `Alkemist.Controller`
  """
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def register_menu_item(module, label, opts) do
    ensure_started()

    if label == false do
      unregister_menu_item(module)
    else
      menu =
        opts
        |> Keyword.put(:label, label)
        |> Keyword.put_new(:index, 0)
        |> Keyword.put_new(:parent, nil)
        |> Enum.into(%{})

      Agent.update(__MODULE__, fn state ->
        Map.put(state, module, menu)
      end)
    end
  end

  def unregister_menu_item(module) do
    ensure_started()
    Agent.update(__MODULE__, fn state ->
      Map.delete(state, module)
    end)
  end

  def cleanup do
    ensure_started()
    Agent.update(__MODULE__, fn _state -> %{} end)
  end

  def menu_items do
    ensure_started()

    Agent.get(__MODULE__, fn state ->
      state
      |> Enum.map(fn {_, menu} -> menu end)
      |> build_tree()
      |> sort()
    end)
  end

  defp ensure_started do
    case Process.whereis(__MODULE__) do
      nil -> start_link([])
      _pid -> :ok
    end
  end


  defp sort(menu_items) do
    Enum.sort_by(menu_items, fn i -> {i.index, String.first(i.label)} end)
    |> Enum.map(fn i ->
      if i.type == :branch do
        Map.put(
          i,
          :children,
          Enum.sort_by(i.children, fn i -> {i.index, String.first(i.label)} end)
        )
      else
        i
      end
    end)
  end

  defp build_tree(items, results \\ [])

  defp build_tree([item | tail], results) do
    item = item |> Map.put(:type, :leaf)

    results =
      if Map.get(item, :parent) == nil do
        results ++ [item]
      else
        case Enum.find_index(results, fn i -> i.label == item.parent end) do
          nil ->
            parent = %{
              label: item.parent,
              type: :branch,
              children: [item],
              index: Map.get(item, :parent_index, 0)
            }

            results ++ [parent]

          index ->
            parent = Enum.at(results, index)
            children = parent.children ++ [item]
            parent = Map.put(parent, :children, children)

            Enum.map(results, fn i ->
              if i.label == item.parent do
                parent
              else
                i
              end
            end)
        end
      end

    build_tree(tail, results)
  end

  defp build_tree([], results), do: results


end
