defmodule Alkemist.ThemeTest do
  use ExUnit.Case, async: false
  import Phoenix.LiveViewTest, only: [render_component: 2]

  defmodule HostTheme do
    use Alkemist.Theme

    @impl true
    def brand(assigns) do
      ~H|<a href="/" class="ak-brand host-brand">{@title}!</a>|
    end
  end

  defp conn,
    do: Phoenix.ConnTest.build_conn(:get, "/categories") |> Plug.Conn.put_private(:phoenix_router, AlkemistTest.Router)

  test "a host theme overrides one callback and inherits the rest" do
    assert function_exported?(HostTheme, :sidebar, 1)
    assert function_exported?(HostTheme, :app, 1)
    assert render_component(&HostTheme.brand/1, title: "Acme", logo: false) =~ "host-brand"

    assert render_component(&HostTheme.account/1, current_user_name: "me", conn: conn(), alkemist_app: :alkemist) =~
             "me"
  end

  test "the dispatcher picks the theme from the assigns or the config" do
    assert Alkemist.Components.Theme.theme(%{theme: HostTheme}) == HostTheme
    assert Alkemist.Components.Theme.theme(%{alkemist_app: :alkemist}) == Alkemist.Theme.Default
    assert render_component(&Alkemist.Components.Theme.brand/1, theme: HostTheme, title: "Acme", logo: false) =~ "Acme!"

    assert render_component(&Alkemist.Components.Theme.brand/1, title: "Acme", logo: false) =~
             ~s(<span class="ak-brand__name">Acme</span>)
  end

  test "the default app shell renders the sidebar, content and toasts" do
    html =
      render_component(&Alkemist.Layouts.app/1,
        conn: conn(),
        flash: %{"info" => "Saved"},
        page_title: "Categories",
        inner_block: [%{inner_block: fn _, _ -> "PAGE" end}]
      )

    assert html =~ ~r/class="ak-shell[ "]/
    assert html =~ "Alkemist"
    assert html =~ ~s(<nav class="ak-sidebar" aria-label="Main navigation">)
    assert html =~ ~s(class="ak-toasts")
    assert html =~ ~s(href="/categories" class="ak-nav__link" aria-current="page")
    assert html =~ "Saved"
    assert html =~ "PAGE"
    assert html =~ "Skip to content"
  end

  test "head emits configured asset tags" do
    html = render_component(&Alkemist.Theme.Default.head/1, alkemist_app: :alkemist)
    assert html =~ ~s(<link rel="stylesheet" href="/alkemist/assets/alkemist.css")
    assert html =~ ~s(src="/alkemist/assets/alkemist.js")
  end

  test "error pages render without a layout" do
    html = Alkemist.ErrorHTML.render("404.html", %{}) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
    assert html =~ "404"
    assert html =~ "Not Found"
    teapot = Alkemist.ErrorHTML.render("418.html", %{}) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
    assert teapot =~ "418" and teapot =~ "I&#39;m a teapot"
  end
end
