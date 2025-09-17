defmodule Alkemist.LayoutView do
  # Phoenix 1.8 manual template compilation for library
  import Phoenix.HTML
  import Phoenix.HTML.Link
  import Phoenix.HTML.Tag
  import Alkemist.ViewHelpers

  @external_resource "lib/alkemist/templates/layout/app.html.eex"
  @app_template File.read!("lib/alkemist/templates/layout/app.html.eex")

  require EEx
  EEx.function_from_string(:def, :render_app, @app_template, [:assigns], [])

  def render("app.html", assigns) do
    render_app(assigns)
  end

  # Handle partial rendering for templates that call render/2
  def render(partial_template, assigns) do
    case partial_template do
      "_header.html" ->
        render_partial("_header.html.eex", assigns)
      "_flash.html" ->
        render_partial("_flash.html.eex", assigns)
      template_name ->
        # For other templates, try to find and render them
        render_partial(template_name, assigns)
    end
  end

  # Handle module-based rendering for templates that call render/3
  def render(mod, template, assigns) do
    apply(mod, :render, [template, assigns])
  end

  defp render_partial(template_file, assigns) do
    template_path = Path.join(["lib", "alkemist", "templates", "layout", template_file])
    if File.exists?(template_path) do
      template_content = File.read!(template_path)
      EEx.eval_string(template_content, assigns: assigns)
    else
      # Fallback to empty content if template not found
      ""
    end
  end
end
