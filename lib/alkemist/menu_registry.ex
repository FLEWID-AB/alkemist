defmodule Alkemist.MenuRegistry do
  @moduledoc """
  The MenuRegistry is used to store and retrieve menu items for the
  sidebar.

  You can define custom labels and options in your resource controllers.
  See `Alkemist.Controller`
  """
  use GenServer

  @me __MODULE__

  def start(args \\ []) do
    GenServer.start(__MODULE__, args, name: @me)
  end

  def init(args) do
    {:ok, args}
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

      GenServer.cast(@me, {:set, module, menu})
    end
  end

  def unregister_menu_item(module) do
    ensure_started()

    GenServer.cast(@me, {:remove, module})
  end

  def cleanup do
    GenServer.cast(@me, :remove_all)
  end

  def menu_items do
    ensure_started()

    GenServer.call(@me, :get_all)
    |> Enum.map(fn {_, i} -> i end)
    |> build_tree()
    |> sort()
  end

  def handle_cast({:set, module, menu}, state) do
    state = state |> Keyword.put(module, menu)
    {:noreply, state}
  end

  def handle_cast({:remove, module}, state) do
    state = state |> Keyword.delete(module)
    {:noreply, state}
  end

  def handle_cast(:remove_all, _state) do
    {:noreply, []}
  end

  def handle_call(:get_all, _from, state) do
    {:reply, state, state}
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

  defp ensure_started do
    case Process.whereis(@me) do
      nil -> start()
      _ -> :ok
    end
  end
end
