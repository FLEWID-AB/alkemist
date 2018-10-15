defmodule Alkemist.MenuRegistry do
  @moduledoc """
  The MenuRegistry is used to store and retrieve menu items for the
  sidebar.

  You can define custom labels and options in your resource controllers.
  See `Alkemist.Controller`
  """

  def register_menu_item(module, label, opts) do
    ensure_setup()

    if label == false do
      unregister_menu_item(module)
    else
      menu =
        opts
        |> Keyword.put(:label, label)
        |> Keyword.put_new(:index, 0)
        |> Keyword.put_new(:parent, nil)
        |> Enum.into(%{})

      add_menu(module, menu)
    end
  end

  def unregister_menu_item(module) do
    ensure_setup()
    remove_menu(module)
  end

  def cleanup do
    delete_all()
  end

  def menu_items do
    ensure_setup()

    get_cached_menu_items()
    |> Enum.map(fn {_, i} -> i end)
    |> build_tree()
    |> sort()
  end

  defp add_menu(module, menu) do
    case Poison.encode(menu) do
      {:ok, json} -> File.write(module_path(module), json)
      _ -> :ok
    end
  end

  defp remove_menu(module) do
    if File.exists?(module_path(module)) do
      File.rm(module_path(module))
    end
  end

  defp delete_all() do
    ensure_setup()
    case File.ls(cache_path()) do
      {:ok, files} ->
        files
        |> Enum.each(fn f ->
          path = Path.join([cache_path(), f])
          File.rm(path)
        end)
      _ -> :error
    end
  end

  defp get_cached_menu_items do
    case File.ls(cache_path()) do
      {:ok, files} ->
        files
        |> Enum.reduce([], fn f, acc ->
          mod = String.to_atom(f)
          content = File.read!(Path.join([cache_path(), f]))
          case Poison.decode(content) do
            {:ok, menu} ->
              menu = AtomicMap.convert(menu, safe: false)
              menu = case Map.get(menu, :resource) do
                nil -> Map.put(menu, :resource, nil)
                val -> Map.put(menu, :resource, String.to_atom(val))
              end
              acc ++ [{mod, menu}]
            _ -> acc ++ [{mod, %{}}]
          end
        end)

      _ -> []
    end
  end

  defp cache_path(path \\ nil) do
    if is_nil(path), do: path = Alkemist.Config.get(:web_interface)
    Path.join([System.tmp_dir!(), "#{path}", "alkemist"])
  end

  defp app_from_module(module) do
    String.split(module, ".") |> Enum.at(1)
  end

  defp module_path(module) do
    app_path = app_from_module(to_string(module))
    Path.join([cache_path(app_path), to_string(module)])
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


  defp ensure_setup do
    unless File.exists?(cache_path()) do
      File.mkdir_p(cache_path())
    end
  end
end
