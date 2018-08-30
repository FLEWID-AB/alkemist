defmodule Alkemist.Controller do
  @moduledoc """
  Provides helper macros to use inside of CRUD controllers.

  ## Usage:

  ```elixir
  defmodule MyAppWeb.MyController do
    use MyAppWeb, :controller

    # Specify the Ecto Schema as resource - it is important to call this above
    # use Alkemist.Controller!
    @resource MyApp.MySchema
    use Alkemist.Controller

  end
  ```

  TODO: document usage of functions like form_partial, columns, etc
  """
  defmacro __using__(_) do
    quote do
      import Alkemist.Assign
      import Alkemist.Controller

      if @resource !== nil do
        menu(Alkemist.Utils.plural_name(@resource))
      end
    end
  end

  alias Alkemist.Assign
  alias Alkemist.Utils

  defmacro menu(label, opts \\ []) do
    quote do
      label = unquote(label)
      opts = unquote(opts) |> Keyword.put(:resource, @resource)
      Alkemist.MenuRegistry.register_menu_item(__MODULE__, label, opts)
    end
  end

  @doc """
  Renders the default index view table. See Alkemist.Assign for possible options
  """
  defmacro render_index(conn, params, opts) do
    quote do
      conn = unquote(conn)

      if Alkemist.Config.authorization_provider().authorize_action(@resource, conn, :index) ==
           true do
        opts = unquote(opts)

        opts =
          Enum.reduce([:repo, :columns, :scopes, :filters, :preload, :search_hook], opts, fn key,
                                                                                             opts ->
            cond do
              Keyword.has_key?(opts, key) ->
                opts

              Keyword.has_key?(__MODULE__.__info__(:functions), key) ->
                Keyword.put(opts, key, apply(__MODULE__, key, []))

              true ->
                opts
            end
          end)

        assigns = Assign.index_assigns(unquote(params), @resource, opts)

        assigns =
          if Keyword.has_key?(__MODULE__.__info__(:functions), :export) do
            Keyword.put(assigns, :has_export, true)
          else
            assigns
          end

        conn
        |> Phoenix.Controller.put_layout(Alkemist.Config.layout())
        |> Phoenix.Controller.render(AlkemistView, "index.html", assigns)
      else
        Alkemist.Controller.forbidden(conn)
      end
    end
  end

  @doc """
  Renders the default show page
  TODO: document methods and options
  """
  defmacro render_show(conn, resource, opts) do
    quote do
      conn = unquote(conn)
      opts = unquote(opts)
      resource = unquote(resource) |> Alkemist.Controller.load_resource(@resource, opts)

      if resource == nil do
        Alkemist.Controller.not_found(conn)
      else
        if Alkemist.Config.authorization_provider().authorize_action(resource, conn, :show) do
          opts =
            Enum.reduce([repo: [], singular_name: [], rows: [], panels: [:show]], opts, fn {key,
                                                                                            v},
                                                                                           opts ->
              cond do
                Keyword.has_key?(opts, key) ->
                  opts

                Keyword.has_key?(__MODULE__.__info__(:functions), key) ->
                  Keyword.put(opts, key, apply(__MODULE__, key, v))

                true ->
                  opts
              end
            end)

          assigns = Assign.show_assigns(resource, opts)

          conn
          |> Phoenix.Controller.put_layout(Alkemist.Config.layout())
          |> Phoenix.Controller.render(AlkemistView, "show.html", assigns)
        else
          Alkemist.Controller.forbidden(conn)
        end
      end
    end
  end

  @doc """
  Renders the "new" action
  TODO: document opts
  """
  defmacro render_new(conn, opts) do
    quote do
      conn = unquote(conn)

      if Alkemist.Config.authorization_provider().authorize_action(@resource, conn, :create) do
        opts =
          unquote(opts)
          |> Keyword.put_new(:changeset, :changeset)

        opts =
          if is_atom(opts[:changeset]) do
            changeset = apply(@resource, opts[:changeset], [@resource.__struct__, %{}])
            Keyword.put(opts, :changeset, changeset)
          else
            opts
          end

        render_form(conn, :new, opts)
      else
        Alkemist.Controller.forbidden(conn)
      end
    end
  end

  @doc """
  Renders the "edit action"
  TODO: document opts
  """
  defmacro render_edit(conn, resource, opts) do
    quote do
      conn = unquote(conn)
      conn = unquote(conn)
      opts = unquote(opts)
      resource = unquote(resource) |> Alkemist.Controller.load_resource(@resource, opts)

      if resource == nil do
        Alkemist.Controller.not_found(conn)
      else
        if Alkemist.Config.authorization_provider().authorize_action(resource, conn, :update) do
          opts =
            opts
            |> Keyword.put_new(:changeset, :changeset)

          opts =
            if is_atom(opts[:changeset]) do
              changeset = apply(@resource, opts[:changeset], [resource, %{}])
              Keyword.put(opts, :changeset, changeset)
            else
              opts
            end

          render_form(conn, :edit, opts)
        else
          Alkemist.Controller.forbidden(conn)
        end
      end
    end
  end

  @doc """
  Renders the form
  TODO: document opts
  """
  defmacro render_form(conn, action, opts) do
    quote do
      opts = unquote(opts)
      action = unquote(action)

      opts =
        Enum.reduce([:form_partial, :fields], opts, fn key, opts ->
          cond do
            Keyword.has_key?(opts, key) ->
              opts

            Keyword.has_key?(__MODULE__.__info__(:functions), key) ->
              Keyword.put(opts, key, apply(__MODULE__, key, []))

            true ->
              opts
          end
        end)

      assigns = Assign.form_assigns(@resource, opts)
      conn = unquote(conn)

      conn
      |> Phoenix.Controller.put_layout(Alkemist.Config.layout())
      |> Phoenix.Controller.render(AlkemistView, "#{action}.html", assigns)
    end
  end

  @doc """
  Creates a new resource
  TODO: document opts
  """
  defmacro do_create(conn, params, opts) do
    quote do
      conn = unquote(conn)

      if Alkemist.Config.authorization_provider().authorize_action(@resource, conn, :create) do
        opts =
          unquote(opts)
          |> Keyword.put_new(:changeset, :changeset)

        opts =
          if is_atom(opts[:changeset]) do
            params = unquote(params)
            changeset = apply(@resource, opts[:changeset], [@resource.__struct__, params])
            Keyword.put(opts, :changeset, changeset)
          else
            opts
          end

        repo = Keyword.get(opts, :repo, Alkemist.Config.repo())

        case repo.insert(opts[:changeset]) do
          {:ok, new_resource} ->
            if opts[:success_callback] do
              opts[:success_callback].(new_resource)
            else
              path = String.to_atom("#{Utils.get_struct(@resource)}_path")

              conn
              |> Phoenix.Controller.put_flash(
                :info,
                Utils.singular_name(@resource) <> " created successfully"
              )
              |> Phoenix.Controller.redirect(
                to: apply(Alkemist.Config.router_helpers(), path, [conn, :show, new_resource])
              )
            end

          {:error, changeset} ->
            if opts[:error_callback] do
              opts[:error_callback].(changeset)
            else
              opts = [changeset: changeset]
              render_new(conn, opts)
            end
        end
      else
        Alkemist.Controller.forbidden(conn)
      end
    end
  end

  @doc """
  Performs an update to the resource
  TODO: document opts
  """
  defmacro do_update(conn, resource, params, opts) do
    quote do
      conn = unquote(conn)
      opts = unquote(opts)
      resource = unquote(resource) |> Alkemist.Controller.load_resource(@resource, opts)

      if resource == nil do
        Alkemist.Controller.not_found(conn)
      else
        if Alkemist.Config.authorization_provider().authorize_action(resource, conn, :update) do
          params = unquote(params)

          opts =
            opts
            |> Keyword.put_new(:changeset, :changeset)

          opts =
            if is_atom(opts[:changeset]) do
              params = unquote(params)
              changeset = apply(@resource, opts[:changeset], [resource, params])
              Keyword.put(opts, :changeset, changeset)
            else
              opts
            end

          repo = Keyword.get(opts, :repo, Alkemist.Config.repo())

          case repo.update(opts[:changeset]) do
            {:ok, new_resource} ->
              if opts[:success_callback] do
                opts[:success_callback].(new_resource)
              else
                path = String.to_atom("#{Utils.get_struct(@resource)}_path")

                conn
                |> Phoenix.Controller.put_flash(
                  :info,
                  Utils.singular_name(@resource) <> " updated successfully"
                )
                |> Phoenix.Controller.redirect(
                  to: apply(Alkemist.Config.router_helpers(), path, [conn, :show, new_resource])
                )
              end

            {:error, changeset} ->
              if opts[:error_callback] do
                opts[:error_callback].(changeset)
              else
                opts = [changeset: changeset]
                render_edit(conn, resource, opts)
              end
          end
        else
          Alkemist.Controller.forbidden(conn)
        end
      end
    end
  end

  @doc """
  TODO: document opts
  """
  defmacro do_delete(conn, resource, opts) do
    quote do
      conn = unquote(conn)
      opts = unquote(opts)
      resource = unquote(resource) |> Alkemist.Controller.load_resource(@resource, opts)

      if resource == nil do
        Alkemist.Controller.not_found(conn)
      else
        if Alkemist.Config.authorization_provider().authorize_action(resource, conn, :delete) do
          res =
            if opts[:delete_func] do
              opts[:delete_func].(resource)
            else
              repo = Keyword.get(opts, :repo, Alkemist.Config.repo())
              repo.delete(resource)
            end

          case res do
            {:ok, deleted} ->
              if opts[:success_callback] do
                opts[:success_callback].(deleted)
              else
                path = String.to_atom("#{Utils.get_struct(@resource)}_path")

                conn
                |> Phoenix.Controller.put_flash(
                  :info,
                  Utils.singular_name(@resource) <> " deleted successfully"
                )
                |> Phoenix.Controller.redirect(
                  to: apply(Alkemist.Config.router_helpers(), path, [conn, :index])
                )
              end

            {:error, message} ->
              if opts[:error_callback] do
                opts[:error_callback].(message)
              else
                path = String.to_atom("#{Utils.get_struct(@resource)}_path")

                conn
                |> Phoenix.Controller.put_layout(Alkemist.Config.layout())
                |> Phoenix.Controller.put_flash(:error, "Oops, something went wrong")
                |> Phoenix.Controller.redirect(
                  to: apply(Alkemist.Config.router_helpers(), path, [conn, :index])
                )
              end
          end
        else
          Alkemist.Controller.forbidden(conn)
        end
      end
    end
  end

  @doc """
  TODO: document opts
  """
  defmacro csv(conn, params, opts \\ []) do
    quote do
      conn = unquote(conn)
      opts = unquote(opts)
      params = unquote(params)

      opts =
        cond do
          Keyword.has_key?(opts, :columns) ->
            opts

          Keyword.has_key?(__MODULE__.__info__(:functions), :csv_columns) ->
            Keyword.put(opts, :columns, apply(__MODULE__, :csv_columns, []))

          Keyword.has_key?(__MODULE__.__info__(:functions), :columns) ->
            Keyword.put(opts, :columns, apply(__MODULE__, :columns, []))

          true ->
            opts
        end

      opts =
        Enum.reduce([:repo, :search_hook], opts, fn key, opts ->
          cond do
            Keyword.has_key?(opts, key) ->
              opts

            Keyword.has_key?(__MODULE__.__info__(:functions), key) ->
              Keyword.put(opts, key, apply(__MODULE__, key, []))

            true ->
              opts
          end
        end)

      assigns = Assign.csv_assigns(params, @resource, opts)
      csv = Alkemist.CSVExport.create_csv(assigns[:columns], assigns[:entries])

      conn
      |> Plug.Conn.put_resp_content_type("text/csv")
      |> Plug.Conn.put_resp_header("content-disposition", "attachment; filename=\"export.csv\"")
      |> Plug.Conn.send_resp(200, csv)
    end
  end

  # TODO: see if we can make the methods below private somehow
  def add_opt(opts, controller, key, atts \\ []) do
    cond do
      Keyword.has_key?(opts, key) ->
        opts

      Keyword.has_key?(controller.__info__(:functions), key) ->
        Keyword.put(opts, key, apply(controller, key, atts))

      true ->
        opts
    end
  end

  def forbidden(conn) do
    conn
    |> Phoenix.Controller.put_layout(Alkemist.Config.layout())
    |> Phoenix.Controller.put_flash(:error, "You are not authorized to access this page")
    |> Phoenix.Controller.redirect(
      to: Alkemist.Config.router_helpers().page_path(conn, :dashboard)
    )
  end

  def not_found(conn) do
    conn
    |> Plug.Conn.put_status(:not_found)
    |> Phoenix.Controller.render(Alkemist.ErrorView, "404.html")
  end

  @doc """
  Loads the resource from the repo and adds any preloads
  """
  def load_resource(resource, mod, opts) when is_bitstring(resource),
    do: load_resource(String.to_integer(resource), mod, opts)

  def load_resource(resource, mod, opts) when is_integer(resource) do
    repo = Keyword.get(opts, :repo, Alkemist.Config.repo())
    load_resource(repo.get(mod, resource), mod, opts)
  end

  def load_resource(resource, _mod, opts) do
    if opts[:preload] do
      repo = Keyword.get(opts, :repo, Alkemist.Config.repo())
      resource |> repo.preload(opts[:preload])
    else
      resource
    end
  end
end
