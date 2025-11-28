defmodule Alkemist.ErrorView do
  use Phoenix.View,
    root: "lib/alkemist/templates",
    namespace: Alkemist

  import Phoenix.HTML

  @doc """
  Renders error templates.
  By convention, template files are expected in lib/alkemist/templates/error/
  """

  # In case no render clause matches or no template is found,
  # template_not_found function is invoked
  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
