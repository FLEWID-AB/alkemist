defmodule Alkemist.Theme do
  @moduledoc """
  The behaviour a host implements to change how Alkemist looks.

  Configure it with `config :my_app, Alkemist, theme: MyAppWeb.AlkemistTheme` (or pass
  `theme:` to a controller macro) and define only the callbacks you want to change; every
  other callback is delegated to `Alkemist.Theme.Default` at compile time.

      defmodule MyAppWeb.AlkemistTheme do
        use Alkemist.Theme

        @impl true
        def brand(assigns) do
          ~H|<a href="/" class="ak-brand"><img src="/images/logo.svg" alt="MyApp" /></a>|
        end

        @impl true
        def account(assigns) do
          ~H|<.account_footer name={@current_user_name} environment="Staging" sign_out={[path: "/logout", method: :delete]} />|
        end
      end

  All component callbacks receive the page assigns (`conn`, `alkemist_app`, `flash`,
  `page_title`, ...) plus what the docs of each callback list.
  """

  @type assigns :: map()

  @doc "The application shell around every page. Receives `inner_block`. The default is `Alkemist.Theme.Default`'s shell."
  @callback app(assigns()) :: Phoenix.LiveView.Rendered.t()
  @doc "Tags for `<head>`: stylesheet and script. Receives `alkemist_app`."
  @callback head(assigns()) :: Phoenix.LiveView.Rendered.t()
  @doc "The brand at the top of the sidebar. Receives `title`, `subtitle`, `logo`."
  @callback brand(assigns()) :: Phoenix.LiveView.Rendered.t()
  @doc "The account footer of the sidebar. Receives `conn`, `current_user_name`, `environment`, `sign_out`."
  @callback account(assigns()) :: Phoenix.LiveView.Rendered.t()
  @doc "The navigation in the sidebar. Receives `menu_items`, `conn`, `current_path`."
  @callback sidebar(assigns()) :: Phoenix.LiveView.Rendered.t()
  @doc "Cards in the right column of index and show pages. Receives `sidebars`, `page_assigns`."
  @callback aside(assigns()) :: Phoenix.LiveView.Rendered.t()
  @doc "Flash messages. Receives `flash`."
  @callback flash_group(assigns()) :: Phoenix.LiveView.Rendered.t()
  @doc "The filter form. Receives `filters`, `filter_form`, `paths`, `link_params`, `expanded`, `search`."
  @callback filters(assigns()) :: Phoenix.LiveView.Rendered.t()
  @doc "One filter's label and input. Receives `form`, `filter` (`{field, opts}`)."
  @callback filter_field(assigns()) :: Phoenix.LiveView.Rendered.t()
  @doc "The pagination bar. Receives `pagination`, `entries_count`, `paths`, `link_params`."
  @callback pagination(assigns()) :: Phoenix.LiveView.Rendered.t()
  @doc "A cell value. Receives `value`, `column`, `row`. Escape by default!"
  @callback value(assigns()) :: Phoenix.LiveView.Rendered.t()
  @doc "The member-actions header (`header?`) or row cell. Receives `actions`, `resource`, `paths`, `conn`."
  @callback member_actions(assigns()) :: Phoenix.LiveView.Rendered.t()
  @doc "CSS classes for a table row."
  @callback row_class(row :: struct(), default :: String.t()) :: String.t() | list()
  @doc "The whole edit/new form. Receives `form`, `action`, `form_method`, `form_fields`, `struct`, `paths`."
  @callback resource_form(assigns()) :: Phoenix.LiveView.Rendered.t()
  @doc "One form field. Receives `form`, `field` (`{key, opts}`)."
  @callback form_field(assigns()) :: Phoenix.LiveView.Rendered.t()

  @callbacks [
    app: 1,
    head: 1,
    brand: 1,
    account: 1,
    sidebar: 1,
    aside: 1,
    flash_group: 1,
    filters: 1,
    filter_field: 1,
    pagination: 1,
    value: 1,
    member_actions: 1,
    row_class: 2,
    resource_form: 1,
    form_field: 1
  ]

  @doc false
  def callbacks, do: @callbacks

  defmacro __using__(_opts) do
    quote do
      use Alkemist.HTML
      @behaviour Alkemist.Theme
      @before_compile Alkemist.Theme
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    for {name, arity} <- @callbacks, not Module.defines?(env.module, {name, arity}) do
      args = Macro.generate_arguments(arity, env.module)

      quote do
        @impl Alkemist.Theme
        def unquote(name)(unquote_splicing(args)), do: Alkemist.Theme.Default.unquote(name)(unquote_splicing(args))
      end
    end
  end
end
