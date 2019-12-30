defmodule Alkemist.Types.Action do
  @moduledoc """
  Representation of an action - can be a member action or a collection action.

  Also provides handy functionality to create action structs from controller definition.
  """
  alias Alkemist.Utils

  @enforce_keys [:action, :type]

  @default_collection_actions ~w(new)a
  @default_member_actions ~w(show edit delete)a
  @default_action_opts [
    delete: %{
      link_opts: [
        method: :delete,
        data: [
          confirm: "Do you really want to delete this item?"
        ]
      ]
    }
  ]

  defstruct [
    :action,
    :label,
    :type,
    class: "",
    link_opts: []
  ]

  @type t :: %__MODULE__{
    action: atom(),
    label: String.t(),
    type: action_type(),
    link_opts: keyword()
  }

  @typep action_type :: :member | :collection

  @doc """
  Maps an action

  ## Examples

    iex> Alkemist.Types.Action.map(:edit, :member)
    %Alkemist.Types.Action{label: "Edit", type: :member, action: :edit}

    iex> Alkemist.Types.Action.map({:edit, %{class: "custom"}}, :member)
    %Alkemist.Types.Action{label: "Edit", class: "custom", type: :member, action: :edit}
  """
  @spec map(map() | t()) :: t()
  def map(%__MODULE__{action: _} = act) do
    act
    |> add_default_opts()
    |> maybe_add_label()
  end

  def map(%{action: _, type: _} = params) do
    params = Map.take(params, Map.keys(%__MODULE__{action: :action, type: :member}))
    map(struct!(__MODULE__, params))
  end

  @spec map(atom() | tuple(), action_type()) :: t()
  def map(action, type) when is_atom(action) do
    map(%{action: action, type: type})
  end

  def map({action, opts}, type) do
    if is_map(opts) do
      opts
      |> Map.put(:type, type)
      |> Map.put(:action, action)
      |> map()
    else
      opts = opts
      |> Enum.into(%{})

      map({action, opts}, type)
    end
  end

  @doc """
  Maps a list of actions

  ## Examples

    iex> Alkemist.Types.Action.map_all([:edit, :custom], :member)
    [%Alkemist.Types.Action{action: :edit, label: "Edit", type: :member}, %Alkemist.Types.Action{action: :custom, label: "Custom", type: :member}]
  """
  @spec map_all(list(), action_type()) :: [t()]
  def map_all(actions, type) do
    actions
    |> Enum.map(& map(&1, type))
  end

  defp add_default_opts(action) do
    if Keyword.has_key?(@default_action_opts, action.action) do
      keys = Map.keys(action)
      params = Map.take(Keyword.get(@default_action_opts, action.action), keys)

      Enum.reduce(Map.to_list(params), action, fn ({k, v}, action) ->
        if Map.get(action, k) in [nil, [], "", %{}] do
          Map.put(action, k, v)
        else
          action
        end
      end)
    else
      action
    end
  end

  defp maybe_add_label(%{label: label, action: action} = act) when is_nil(label) do
    Map.put(act, :label, Utils.to_label(action))
  end
  defp maybe_add_label(action), do: action

  @spec default_collection_actions() :: list()
  def default_collection_actions, do: @default_collection_actions

  @spec default_member_actions() :: list()
  def default_member_actions, do: @default_member_actions
end
