defmodule Alkemist.Menu do
  @moduledoc """
  Sidebar menu items, discovered **at runtime from the host router**.

  Every controller that `use`s `Alkemist.Controller` exports `__alkemist_menu__/0`
  (customised with the `menu/2` macro). `items/1` walks `Phoenix.Router.routes/1`, collects
  those items, groups children under their `parent` label and sorts by `{index, label}`.
  Because nothing is registered in a process, the menu is complete in releases and after
  code reloading alike.

  Set `config :my_app, Alkemist, menu_cache: true` to memoise the tree per router in
  `:persistent_term`; call `reset/1` to drop it.
  """

  @type item :: %{
          controller: module(),
          resource: module() | String.t(),
          label: String.t(),
          parent: String.t() | nil,
          index: integer(),
          parent_index: integer() | nil,
          to: String.t() | nil,
          icon: String.t() | nil,
          type: :leaf
        }

  @type branch :: %{label: String.t(), type: :branch, index: integer(), children: [item()]}

  @doc false
  # The item a controller gets by default: its resource's plural label, or none.
  def default_item(_controller, nil), do: nil

  def default_item(controller, resource) when is_binary(resource),
    do: item(controller, resource, resource, [])

  def default_item(controller, resource),
    do: item(controller, resource, Alkemist.Naming.plural_label(resource), [])

  @doc false
  def item(_controller, _resource, false, _opts), do: nil

  def item(controller, resource, label, opts) when is_binary(label) do
    %{
      controller: controller,
      resource: if(is_nil(resource) or is_binary(resource), do: label, else: resource),
      label: label,
      parent: Keyword.get(opts, :parent),
      index: Keyword.get(opts, :index, 0),
      parent_index: Keyword.get(opts, :parent_index),
      to: Keyword.get(opts, :to),
      icon: Keyword.get(opts, :icon),
      type: :leaf
    }
  end

  @doc "The menu tree for the router that dispatched `conn`, or for `router`."
  @spec items(Plug.Conn.t() | module(), keyword()) :: [item() | branch()]
  def items(conn_or_router, opts \\ [])

  def items(%Plug.Conn{} = conn, opts), do: items(Alkemist.Routes.router!(conn), opts)

  def items(router, opts) when is_atom(router) do
    if Keyword.get(opts, :cache, false) do
      key = {__MODULE__, router}

      case :persistent_term.get(key, nil) do
        nil ->
          tree = build(router)
          :persistent_term.put(key, tree)
          tree

        tree ->
          tree
      end
    else
      build(router)
    end
  end

  @doc "Drops the cached tree for `router`."
  @spec reset(module()) :: :ok
  def reset(router) do
    :persistent_term.erase({__MODULE__, router})
    :ok
  end

  @doc false
  def __test_build_tree__(items), do: items |> build_tree() |> sort()

  defp build(router) do
    router
    |> Phoenix.Router.routes()
    |> Enum.filter(&(&1.plug_opts == :index))
    |> Enum.map(& &1.plug)
    |> Enum.uniq()
    |> Enum.filter(&(Code.ensure_loaded?(&1) and function_exported?(&1, :__alkemist_menu__, 0)))
    |> Enum.map(& &1.__alkemist_menu__())
    |> Enum.reject(&is_nil/1)
    |> build_tree()
    |> sort()
  end

  defp build_tree(items) do
    Enum.reduce(items, [], fn
      %{parent: nil} = item, tree ->
        tree ++ [item]

      %{parent: parent} = item, tree ->
        case Enum.find_index(tree, &(&1.type == :branch and &1.label == parent)) do
          nil ->
            tree ++
              [%{label: parent, type: :branch, index: item.parent_index || 0, children: [item]}]

          i ->
            List.update_at(tree, i, fn branch ->
              branch
              |> Map.update!(:children, &(&1 ++ [item]))
              |> Map.update!(:index, &max_index(&1, item.parent_index))
            end)
        end
    end)
  end

  defp max_index(current, nil), do: current
  defp max_index(_current, given), do: given

  defp sort(tree) do
    tree
    |> Enum.sort_by(&{&1.index, &1.label})
    |> Enum.map(fn
      %{type: :branch, children: children} = branch ->
        %{branch | children: Enum.sort_by(children, &{&1.index, &1.label})}

      leaf ->
        leaf
    end)
  end
end
