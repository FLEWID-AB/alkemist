defmodule Mix.Tasks.Alkemist.Gen.Controller do
  @moduledoc """
  Generate a boilerplate controller for Alkemist

  ## Usage

  args: ModuleBaseName, ModelModule, WebNamespace

  Creates a new controller file:

    mix alkemist.gen.controller User MyApp.User

  will create `lib/app_web/controllers/user_controller.ex`.

  ## Using a custom namespace:

    mix alkemist.gen.controller User MyApp.User Admin

  will create `lib/app_web/controllers/admin/user_controller.ex`
  """

  use Mix.Task

  @doc false
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix alkemist.gen.controller can only be run inside an application directory")
    end

    if Enum.count(args) < 2 do
      Mix.raise("mix.alkemist.gen.controller needs the module name and model name")
    end

    resource = Enum.at(args, 0)
    model = Enum.at(args, 1)
    namespace = Enum.at(args, 2)

    schema = build_schema(resource, model, namespace)
    context = %{schema: schema, context_app: Mix.Phoenix.context_app()}

    copy_files(context)
  end

  defp copy_files(%{schema: schema} = context) do
    files = files_to_generate(context)
    bindings = Map.to_list(schema)
    template_path = Path.join([package_path() | ~w(priv templates)])

    Enum.each(files, fn {tpl, dest_path} ->
      source_file = Path.join([template_path, tpl])
      source = source_file |> EEx.eval_file(bindings)
      File.write!(dest_path, source)
      IO.puts("Created controller at #{dest_path}")
      IO.puts("")
      IO.puts("Please add the route to your router.ex:")
      IO.puts("alkemist_resources \"/#{schema.plural}\", #{schema.resource}Controller")
    end)
  end

  defp files_to_generate(%{schema: schema, context_app: context_app}) do
    web_prefix = Mix.Phoenix.web_path(context_app)
    web_path = to_string(schema.web_path)

    [
      {"controller.ex",
       Path.join([web_prefix, "controllers", web_path, "#{schema.singular}_controller.ex"])}
    ]
  end

  defp build_schema(resource, model, namespace) do
    module = ("Elixir." <> resource) |> String.to_atom()
    singular = String.split(resource, ".") |> List.last() |> Phoenix.Naming.underscore()
    source = Inflex.pluralize(singular)

    %{
      controller_name: controller_name(namespace, resource),
      base_module: Module.concat([Mix.Phoenix.context_app()]),
      module: module,
      model: model,
      resource: resource,
      plural: source,
      singular: singular,
      web_module: "#{web_module()}" |> String.replace("Elixir.", ""),
      web_namespace: namespace,
      web_path: namespace && Phoenix.Naming.underscore(namespace)
    }
  end

  defp controller_name(namespace, resource) do
    mod = "#{web_module()}" |> String.replace("Elixir.", "")

    Enum.join([mod, namespace, resource], ".")
    |> String.replace("..", ".")
  end

  defp web_module do
    base = Mix.Phoenix.base()

    cond do
      Mix.Phoenix.context_app() != Mix.Phoenix.otp_app() -> Module.concat([base])
      String.ends_with?(base, "Web") -> Module.concat([base])
      true -> Module.concat(["#{base}Web"])
    end
  end

  defp package_path do
    __ENV__.file
    |> Path.dirname()
    |> String.split("/lib/mix/tasks")
    |> hd()
  end
end
