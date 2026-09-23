defmodule Alkemist.ComponentsTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest, only: [render_component: 2, rendered_to_string: 1]
  import Phoenix.Component

  alias Alkemist.Components.{Core, Icons, Layout, Menu}

  defp conn,
    do: Phoenix.ConnTest.build_conn(:get, "/categories") |> Plug.Conn.put_private(:phoenix_router, AlkemistTest.Router)

  describe "icon" do
    test "known heroicons render inline svg, decorative by default" do
      html = render_component(&Icons.icon/1, name: "hero-trash", class: "size-4")
      assert html =~ "<svg"
      assert html =~ ~s(aria-hidden="true")
      assert html =~ ~s(class="ak-icon size-4")
      assert "hero-trash" in Icons.builtin()
    end

    test "aria-label makes it meaningful and unknown names fall back to a class" do
      assert render_component(&Icons.icon/1, name: "hero-trash", "aria-label": "Delete") =~ ~s(aria-label="Delete")
      refute render_component(&Icons.icon/1, name: "hero-trash", "aria-label": "Delete") =~ "aria-hidden"
      assert render_component(&Icons.icon/1, name: "hero-rocket-launch") =~ ~s(<span class="hero-rocket-launch ak-icon")
      assert_raise ArgumentError, fn -> render_component(&Icons.icon/1, name: "fas fa-eye") end
    end
  end

  describe "core" do
    test "button renders a link or a button with icon" do
      link_html =
        render_component(&Core.button/1,
          href: "/x",
          icon: "hero-plus",
          inner_block: [%{inner_block: fn _, _ -> "New" end}]
        )

      assert link_html =~ ~r/<a href="\/x" class="ak-btn ak-btn--primary[^"]*">\s*<svg.*New\s*<\/a>/s
      refute link_html =~ "data-csrf"

      icon_only = render_component(&Core.button/1, icon: "hero-trash", label: "Delete", variant: "ghost")
      assert icon_only =~ ~s(class="ak-btn ak-btn--ghost ak-btn--icon")
      assert icon_only =~ ~s(aria-label="Delete")

      html =
        render_component(&Core.button/1,
          variant: "danger",
          type: "submit",
          inner_block: [%{inner_block: fn _, _ -> "Go" end}]
        )

      assert html =~ ~s(<button type="submit" class="ak-btn ak-btn--danger)
    end

    test "flash escapes content and uses roles" do
      html = render_component(&Core.flashes/1, flash: %{"error" => "<b>bad</b>", "info" => "ok"})
      assert html =~ ~s(role="alert")
      assert html =~ ~s(role="status")
      assert html =~ "&lt;b&gt;bad&lt;/b&gt;"
      refute html =~ "<b>bad</b>"
    end

    test "badge and empty state" do
      assert render_component(&Core.badge/1, variant: "success", inner_block: [%{inner_block: fn _, _ -> "on" end}]) =~
               "ak-badge--success"

      assert render_component(&Core.empty_state/1, []) =~ "Nothing here yet"

      assert render_component(&Core.badge/1,
               variant: "ok",
               dot: true,
               inner_block: [%{inner_block: fn _, _ -> "Active" end}]
             ) =~ "ak-badge__dot"

      assert Core.format_count(27_850) == "27 850"
    end
  end

  describe "layout" do
    test "brand shows the logo or the title, and the subtitle" do
      assert render_component(&Layout.brand_link/1, title: "Acme", logo: "/images/logo.svg") =~
               ~s(<img src="/images/logo.svg" alt="Acme")

      html = render_component(&Layout.brand_link/1, title: "Acme", subtitle: "Admin", logo: false)
      assert html =~ ~s(<span class="ak-brand__name">Acme</span>)
      assert html =~ ~s(<span class="ak-brand__sub">Admin</span>)
    end

    test "account footer shows the user, environment and sign out" do
      html =
        render_component(&Layout.account_footer/1,
          name: "admin",
          environment: "Production",
          sign_out: [path: "/logout", method: :delete]
        )

      assert html =~ "admin"
      assert html =~ "Production"
      assert html =~ ~s(data-method="delete")
      assert html =~ ~s(aria-label="Sign out")
      assert String.trim(render_component(&Layout.account_footer/1, name: nil)) == ""
    end
  end

  describe "menu" do
    test "renders leaves with router-derived paths and marks the current page" do
      html =
        render_component(&Menu.sidebar_nav/1,
          items: Alkemist.Menu.items(AlkemistTest.Router),
          conn: conn(),
          current_path: "/categories/3"
        )

      assert html =~
               ~r/<a href="\/categories" class="ak-nav__link" aria-current="page">\s*<svg.*?<\/svg>\s*<span>Categories<\/span>/s

      assert html =~ ~r/<a href="\/posts" class="ak-nav__link">\s*<span>Posts<\/span>/
    end

    test "groups children into open branches and hides unauthorized leaves" do
      items =
        Alkemist.Menu.__test_build_tree__([
          Alkemist.Menu.item(AlkemistTest.PostController, Alkemist.Post, "Posts",
            parent: "Content",
            icon: "hero-document-text"
          ),
          Alkemist.Menu.item(X, nil, "Reports", to: "/reports")
        ])

      html = render_component(&Menu.sidebar_nav/1, items: items, conn: conn(), current_path: "/posts")
      assert html =~ ~s(<details class="ak-nav__group" open>)
      assert html =~ ~r/<a href="\/posts" class="ak-nav__link" aria-current="page">\s*<svg/
      assert html =~ "Content"
      assert html =~ ~s(href="/reports")
    end
  end
end
