defmodule Alkemist.Theme.Default do
  @moduledoc """
  The default `Alkemist.Theme`: a left sidebar with brand, navigation and account
  footer; each page brings its own header band and content.
  """
  use Alkemist.HTML
  @behaviour Alkemist.Theme

  alias Alkemist.{Authorization, Config}

  @impl true
  def app(assigns) do
    assigns =
      assigns
      |> Map.put_new(:alkemist_app, :alkemist)
      |> Map.put_new(:flash, %{})
      |> Map.put_new(:theme, nil)
      |> then(&Map.put(&1, :current_path, &1[:current_path] || (&1[:conn] && &1.conn.request_path)))

    ~H"""
    <.shell>
      <:sidebar>
        <Theme.brand
          alkemist_app={@alkemist_app}
          theme={@theme}
          title={Config.get(:title, @alkemist_app)}
          subtitle={Config.get(:subtitle, @alkemist_app)}
          logo={Config.get(:logo, @alkemist_app)}
        />
        <Theme.sidebar
          alkemist_app={@alkemist_app}
          theme={@theme}
          conn={@conn}
          current_path={@current_path}
          menu_items={Alkemist.Menu.items(@conn, cache: Config.get(:menu_cache, @alkemist_app))}
        />
        <Theme.account
          alkemist_app={@alkemist_app}
          theme={@theme}
          conn={@conn}
          current_user_name={Authorization.current_user_name(Config.authorization_provider(@alkemist_app), @conn)}
          environment={Config.get(:environment, @alkemist_app)}
          sign_out={Config.get(:sign_out, @alkemist_app)}
        />
      </:sidebar>
      {render_slot(@inner_block)}
      <Theme.flash_group alkemist_app={@alkemist_app} theme={@theme} flash={@flash} />
    </.shell>
    """
  end

  @impl true
  def head(assigns) do
    assigns = Map.put_new(assigns, :alkemist_app, :alkemist)
    assets = Config.get(:assets, assigns.alkemist_app)
    assigns = Map.merge(assigns, %{css: assets[:css], js: assets[:js]})

    ~H"""
    <link :if={@css} rel="stylesheet" href={@css} />
    <script :if={@js} defer type="module" src={@js}>
    </script>
    """
  end

  @impl true
  def brand(assigns) do
    assigns =
      assigns |> Map.put_new(:alkemist_app, :alkemist) |> Map.put_new(:subtitle, nil) |> Map.put_new(:logo, false)

    ~H"""
    <.brand_link title={@title} subtitle={@subtitle} logo={@logo} href={Config.get(:home_path, @alkemist_app)} />
    """
  end

  @impl true
  def account(assigns) do
    assigns =
      assigns |> Map.put_new(:current_user_name, nil) |> Map.put_new(:environment, nil) |> Map.put_new(:sign_out, nil)

    ~H"""
    <.account_footer name={@current_user_name} environment={@environment} sign_out={@sign_out} />
    """
  end

  @impl true
  def sidebar(assigns) do
    ~H"""
    <.sidebar_nav items={@menu_items} conn={@conn} current_path={@current_path} alkemist_app={@alkemist_app} />
    """
  end

  @impl true
  def aside(assigns) do
    ~H"""
    <.aside_panel :for={{label, opts} <- @sidebars} title={to_string(label)}>
      {panel_content(opts, @page_assigns)}
    </.aside_panel>
    """
  end

  @impl true
  def flash_group(assigns) do
    ~H"""
    <.flashes flash={@flash} />
    """
  end

  @impl true
  def filters(assigns) do
    ~H"""
    <Alkemist.Components.Filters.filter_form
      filters={@filters}
      filter_form={@filter_form}
      paths={@paths}
      link_params={@link_params}
      search={@search}
      alkemist_app={@alkemist_app}
      theme={assigns[:theme]}
    />
    """
  end

  @impl true
  def filter_field(assigns) do
    ~H"""
    <Alkemist.Components.Filters.filter_field form={@form} filter={@filter} paths={@paths} link_params={@link_params} />
    """
  end

  @impl true
  def pagination(assigns) do
    assigns = Map.put_new(assigns, :alkemist_app, :alkemist)

    ~H"""
    <Alkemist.Components.Pagination.pagination
      pagination={@pagination}
      entries_count={@entries_count}
      paths={@paths}
      link_params={@link_params}
      per_page_options={Config.pagination(@alkemist_app)[:per_page_options]}
    />
    """
  end

  @impl true
  def value(assigns) do
    ~H"""
    <Alkemist.Components.Value.value value={@value} column={assigns[:column] || %{}} row={assigns[:row]} />
    """
  end

  @impl true
  def member_actions(%{header?: true} = assigns) do
    ~H"""
    <th scope="col" class="ak-th ak-th--actions"><span class="sr-only">{gettext("Actions")}</span></th>
    """
  end

  def member_actions(assigns) do
    assigns =
      assigns
      |> Map.put_new(:alkemist_app, :alkemist)
      |> Map.put(:menu_id, "ak-row-actions-#{Alkemist.Components.Table.pk(assigns.resource)}")

    ~H"""
    <td class="ak-td ak-td--actions">
      <.dropdown
        id={@menu_id}
        label={gettext("More actions")}
        icon="hero-ellipsis-horizontal"
        icon_only
        variant="ghost"
        size="sm"
      >
        <Alkemist.Components.Actions.action_link
          :for={action <- @actions}
          action={action}
          resource={@resource}
          paths={@paths}
          conn={@conn}
          alkemist_app={@alkemist_app}
          variant="menu"
        />
      </.dropdown>
    </td>
    """
  end

  @impl true
  def row_class(_row, default), do: default

  @impl true
  def resource_form(assigns) do
    # May be called as a plain function from a template, so no assign_new/3 here.
    assigns = Map.put_new(assigns, :alkemist_app, :alkemist)

    ~H"""
    <.form :let={f} for={@form} action={@action} id={"#{@struct}-form"} class="ak-form" method={@form_method}>
      <Alkemist.Components.Form.errors_summary form={@form} />
      <Alkemist.Components.Form.field_group :for={group <- @form_fields} title={group[:title]}>
        <Theme.form_field
          :for={field <- group.fields}
          form={f}
          field={field}
          alkemist_app={@alkemist_app}
          theme={assigns[:theme]}
        />
      </Alkemist.Components.Form.field_group>
      <div class="ak-form__actions">
        <.button type="submit">{gettext("Save")}</.button>
        <.button :if={assigns[:paths]} href={Paths.for(@paths, :index)} variant="ghost">{gettext("Cancel")}</.button>
      </div>
    </.form>
    """
  end

  @impl true
  def form_field(assigns) do
    assigns = Map.put_new(assigns, :alkemist_app, :alkemist)

    ~H"""
    <Alkemist.Components.Form.field form={@form} field={@field} alkemist_app={@alkemist_app} theme={assigns[:theme]} />
    """
  end

  @doc """
  Content of a panel or sidebar definition: `component: {mod, fun}` or a capture is called
  with the page assigns; `content:` is rendered escaped unless it is already safe HTML.
  """
  def panel_content(opts, page_assigns) do
    opts = Map.new(opts)

    cond do
      component = opts[:component] -> call_component(component, page_assigns)
      Map.has_key?(opts, :content) -> opts[:content]
      true -> nil
    end
  end

  defp call_component({mod, fun}, assigns), do: apply(mod, fun, [assigns])
  defp call_component(fun, assigns) when is_function(fun, 1), do: fun.(assigns)
end
