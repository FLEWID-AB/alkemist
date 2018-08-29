defmodule Alkemist.Router do
  @moduledoc """
  Provides helper functions to generate admin resource paths.

  ## Usage:

  ```elixir
  defmodule MyApp.Router do
    use Phoenix.Router
    use Alkemist.Router

  end
  ```
  """
  use Phoenix.Router
  @supported_actions [:index, :edit, :new, :show, :create, :update, :delete]

  @doc false
  defmacro __using__(_opts \\ []) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Registers the routes for a manager resource

  ## Usage:

  ```
  defmodule MyApp.Router do
    ...

    scope "/admin", MyApp do
      pipe_through :browser
      manager_resources "/users", UserController, except: [:delete]
    end
  end
  ```

  Possible options are:
  * :except - Array of actions to exclude from generating the routes
  * :only - when provided, only routes for the provided actions are created
  """
  defmacro manager_resources(path, controller, opts) do
    add_resources(path, controller, opts, do: nil)
  end

  @doc """
  See `manager_resources/3`
  """
  defmacro manager_resources(path, controller) do
    add_resources(path, controller, [], do: nil)
  end

  defp add_resources(path, controller, opts, do: context) do
    cleaned_opts =
      opts
      |> clean_opts(:except)
      |> clean_opts(:only)

    quote do
      path = unquote(path)
      controller = unquote(controller)
      opts = unquote(opts)

      if (Keyword.has_key?(opts, :only) == false && Keyword.has_key?(opts, :except) == false) ||
           (Keyword.has_key?(opts, :only) && :export in opts[:only]) ||
           (Keyword.has_key?(opts, :except) && :export not in opts[:except]) do
        get(path <> "/export", controller, :export)
      end

      resources(path, controller, unquote(cleaned_opts), do: unquote(context))
    end
  end

  defp clean_opts(opts, key) do
    if Keyword.has_key?(opts, key) do
      Keyword.put(
        opts,
        key,
        Enum.filter(opts[key], fn o -> o in @supported_actions end)
      )
    else
      opts
    end
  end
end
