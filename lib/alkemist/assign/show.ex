defmodule Alkemist.Assign.Show do
  @moduledoc """
  Handles assigning the needed values to the `show` action in a controller
  """
  @behaviour Alkemist.Assign
  alias Alkemist.{Utils, Assign.Global, Types.Column}

  @doc """
  Generates the default rows to display if not passed by opts.
  Also preloads any defined preloads and creates a Keyword list to assign to the view render

  Params:
    * resource - a row object (e. g. `%Alkemist.Post{}`)
    * opts - additional options (see below)

  Opts:
    * rows - a list of row definitions (same as column definitions)
    * implementation - the main implementation module
    * repo - custom Ecto.Repo
    * member_actions - list of available member actions
    * show_panels - custom html panels
    * preload - a list with Ecto.Query style preloads
  """
  @since "2.0.0"
  @impl Alkemist.Assign
  def assigns(implementation, resource, opts \\ []) do
    struct = resource.__struct__
    opts = default_opts(opts, implementation, struct)
    rows = Enum.map(opts[:rows], & Column.map(&1, resource))

    [
      struct: Utils.get_struct(struct),
      resource: preload(resource, Keyword.get(opts, :preload), Keyword.get(opts, :repo)),
      mod: struct,
      rows: rows,
      panels: Keyword.get(opts, :show_panels, [])
    ]
    |> Keyword.merge(Global.assigns(opts))
    |> Keyword.merge(Keyword.get(opts, :assigns, []))
  end

  @doc """
  Ensures that all needed options are available
  """
  @impl Alkemist.Assign
  def default_opts(opts, implementation, resource) do
    opts
    |> Global.opts(implementation, resource)
    |> Keyword.put_new(:rows, Utils.display_fields(resource))
    |> Keyword.put_new(:resource, resource)
  end

  defp preload(resource, preloads, _) when preloads in [nil, []], do: resource
  defp preload(resource, preloads, repo) do
    repo.preload(resource, preloads)
  end
end
