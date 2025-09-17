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
        # Convert template name to .eex format if needed
        template_file = if String.ends_with?(template, ".html") do
          template |> String.replace(".html", ".html.eex")
        else
          template <> ".html.eex"
        end

        # Get the alkemist app directory
        app_dir = try do
          Application.app_dir(:alkemist)
        rescue
          _ -> File.cwd!()
        end

        # Build comprehensive template paths to check
        template_paths = [
          # Application directory paths
          Path.join([app_dir, "lib", "alkemist", "templates", template_file]),
          Path.join([app_dir, "lib", "alkemist", "templates", "layout", template_file]),
          # Relative paths from current directory
          Path.join(["lib", "alkemist", "templates", template_file]),
          Path.join(["lib", "alkemist", "templates", "layout", template_file]),
          # Deps directory (for when alkemist is used as dependency)
          Path.join(["deps", "alkemist", "lib", "alkemist", "templates", template_file]),
          Path.join(["deps", "alkemist", "lib", "alkemist", "templates", "layout", template_file]),
          # Priv directory fallback
          Path.join([app_dir, "priv", "templates", template_file]),
          Path.join([app_dir, "priv", "templates", "layout", template_file])
        ]

        # Find the first existing template
        existing_template = Enum.find(template_paths, fn path ->
          File.exists?(path)
        end)

        case existing_template do
          nil ->
            # Debug output to help troubleshoot
            paths_checked = Enum.map(template_paths, fn path ->
              "#{path} (exists: #{File.exists?(path)})"
            end) |> Enum.join("<br/>")
            {:safe, "<div>Template #{template} not found. Paths checked:<br/>#{paths_checked}</div>"}
          template_path ->
            try do
              # Read and compile the EEx template
              template_content = File.read!(template_path)
              # Evaluate with proper binding
              compiled = EEx.eval_string(template_content, [assigns: assigns], functions: [{Phoenix.HTML, Phoenix.HTML.__info__(:functions)}])
              {:safe, compiled}
            rescue
              e ->
                {:safe, "<div>Error rendering template #{template} at #{template_path}: #{Exception.message(e)}<br/>#{Exception.format(:error, e, __STACKTRACE__)}</div>"}
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
