defmodule Alkemist.ErrorHTML do
  @moduledoc """
  Error pages. Renders `404.html`/`403.html`/`500.html`; any other status falls back to the
  status message. Usable as a host's `render_errors` formats module too.
  """
  use Alkemist.HTML

  embed_templates "error_html/*"

  def render(template, assigns) do
    status = template |> Path.rootname() |> String.to_integer()

    error_page(
      Map.merge(assigns, %{status: status, message: Phoenix.Controller.status_message_from_template(template)})
    )
  rescue
    ArgumentError -> Phoenix.Controller.status_message_from_template(template)
  end
end
