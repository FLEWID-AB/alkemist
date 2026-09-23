defmodule Alkemist.ResourceHTML do
  @moduledoc """
  The index, show, new and edit pages. Each template wraps itself in `<Layouts.app>` and
  is built from the components in `Alkemist.Components.*`, dispatching customisable parts
  through the configured `Alkemist.Theme`.
  """
  use Alkemist.HTML

  import Alkemist.Components.Table
  import Alkemist.Components.Actions
  import Alkemist.Components.Show

  embed_templates "resource_html/*"

  @doc false
  # The edit action is a header button on the show page; the others go in the "more" menu.
  def edit_action(actions), do: Enum.find(actions, fn {name, _} -> name == :edit end)
  def more_actions(actions), do: Enum.reject(actions, fn {name, _} -> name in [:show, :edit] end)

  @doc false
  # The form: a host-provided `form_partial` component ({mod, fun} or a capture) or the theme's form.
  def form_partial(%{form_partial: {mod, fun}} = assigns) when is_atom(fun), do: apply(mod, fun, [assigns])
  def form_partial(%{form_partial: fun} = assigns) when is_function(fun, 1), do: fun.(assigns)
  def form_partial(assigns), do: Theme.resource_form(assigns)
end
