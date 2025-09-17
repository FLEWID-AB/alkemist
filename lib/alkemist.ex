defmodule Alkemist do
  @moduledoc """
  Alkemist is an admin toolbox for Phoenix applications.
  It allows developers to build admin interfaces in a modular and flexible way
  by providing helper functions to render forms, show- and index pages for resources.

  """

  def view do
    quote do
      # For Phoenix 1.8+, implement render function with EEx template compilation
      def render(template, assigns \\ %{}) do
        # Find template file
        template_file = template |> String.replace(".html", ".html.eex")

        # Build template paths to check
        template_paths = [
          Path.join([Application.app_dir(:alkemist), "lib", "alkemist", "templates", template_file]),
          Path.join([Application.app_dir(:alkemist), "lib", "alkemist", "templates", "layout", template_file]),
          Path.join(["lib", "alkemist", "templates", template_file]),
          Path.join(["lib", "alkemist", "templates", "layout", template_file])
        ]

        # Find the first existing template
        existing_template = Enum.find(template_paths, &File.exists?/1)

        case existing_template do
          nil ->
            {:safe, "<div>Template #{template} not found</div>"}
          template_path ->
            try do
              # Read and compile the EEx template
              template_content = File.read!(template_path)
              compiled = EEx.eval_string(template_content, assigns: assigns)
              {:safe, compiled}
            rescue
              e ->
                {:safe, "<div>Error rendering template #{template}: #{Exception.message(e)}</div>"}
            end
        end
      end

      import Phoenix.Controller, only: [get_flash: 2, view_module: 1]
      use Phoenix.HTML
      import Alkemist.ViewHelpers

      # Helper function to get router helpers from application config
      defp alkemist_router_helpers, do: Application.get_env(:alkemist, :router_helpers)
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
