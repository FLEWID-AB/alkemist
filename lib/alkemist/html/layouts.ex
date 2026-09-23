defmodule Alkemist.Layouts do
  @moduledoc """
  Root layout and the `app/1` shell component, Phoenix 1.8 style.

  Pages are rendered inside `<Layouts.app ...>`; the `<html>`/`<head>` wrapper is the
  `root` template, set as root layout by `Alkemist.Controller`. Hosts may replace the root
  with `root_layout: {MyAppWeb.Layouts, :root}` and the shell by overriding `app/1` in
  their theme.
  """
  use Alkemist.HTML

  embed_templates "layouts/*"

  @doc "The admin shell around page content; delegates to the theme's `app/1`."
  attr :conn, :any, required: true
  attr :flash, :map, default: %{}
  attr :alkemist_app, :atom, default: :alkemist
  attr :theme, :atom, default: nil
  attr :page_title, :string, default: nil
  attr :current_path, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def app(assigns) do
    Theme.app(assigns)
  end
end
