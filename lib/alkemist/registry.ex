defmodule Alkemist.MenuRegistry do
  use GenServer

  @me __MODULE__

  def start(args \\ []) do
    GenServer.start(__MODULE__, args, name: @me)
  end

  def init(args) do
    {:ok, args}
  end

  def register_menu_item(module, menu) do
    ensure_started()
    GenServer.cast(@me, {:set, module, menu})
  end

  def menu_items do
    ensure_started()
    GenServer.call(@me, :get_all)
  end

  def handle_cast({:set, module, menu}, state) do
    state = state |> Keyword.put(module, menu)
    {:noreply, state}
  end

  def handle_call(:get_all, _from, state) do
    {:reply, state, state}
  end

  defp ensure_started do
    case Process.whereis(@me) do
      nil -> start()
      _ -> :ok
    end
  end
end
