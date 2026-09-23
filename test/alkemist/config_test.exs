defmodule Alkemist.ConfigTest do
  use ExUnit.Case, async: false
  alias Alkemist.Config

  @config Application.compile_env(:alkemist, Alkemist, [])

  setup do
    on_exit(fn ->
      Application.put_env(:alkemist, Alkemist, @config)
      Application.delete_env(:other_app, Alkemist)
      Config.reset()
    end)
  end

  defp put_config(otp_app, config) do
    Application.put_env(otp_app, Alkemist, config)
    Config.reset(otp_app)
  end

  test "uses Repo from config" do
    assert @config[:repo] == Config.repo()
  end

  test "theme and root layout default to Alkemist's" do
    assert Config.get(:theme) == Alkemist.Theme.Default
    assert Config.get(:root_layout) == {Alkemist.Layouts, :root}
    assert Config.get(:assets)[:css] == "/alkemist/assets/alkemist.css"
  end

  test "authorization provider returns default" do
    assert Alkemist.Authorization.Permissive == Config.authorization_provider()
  end

  test "forbidden redirect defaults to the root path" do
    assert "/" == Config.forbidden_redirect_to()
  end

  test "nested settings merge over defaults" do
    put_config(:alkemist, repo: Alkemist.Repo, pagination: [max_per_page: 20], assets: [js: nil])

    assert Config.pagination()[:max_per_page] == 20
    assert Config.pagination()[:per_page_options] == [10, 25, 50, 100]
    assert Config.get(:assets) == [css: "/alkemist/assets/alkemist.css", js: nil]
    assert Config.search_provider() == Alkemist.Query.Search
    assert Config.csv()[:separator] == :semicolon
  end

  test "shell keys: subtitle, environment and sign_out" do
    put_config(:alkemist,
      repo: Alkemist.Repo,
      subtitle: "Admin",
      environment: "Production",
      sign_out: [path: "/logout", method: :delete]
    )

    assert Config.get(:subtitle) == "Admin"
    assert Config.get(:environment) == "Production"
    assert Config.get(:sign_out) == [path: "/logout", method: :delete]
  end

  test "unknown keys raise" do
    put_config(:alkemist, repo: Alkemist.Repo, nope: 1)

    assert_raise NimbleOptions.ValidationError, ~r/unknown options \[:nope\]/, fn ->
      Config.repo()
    end
  end

  test "removed keys raise with a pointer" do
    put_config(:alkemist, repo: Alkemist.Repo, router_helpers: Foo.Helpers)

    assert_raise ArgumentError, ~r/router_helpers: was removed in Alkemist 3.0/, fn ->
      Config.repo()
    end

    put_config(:alkemist, repo: Alkemist.Repo, web_interface: "X")
    assert_raise ArgumentError, ~r/web_interface: was removed/, fn -> Config.validate!() end

    put_config(:alkemist, repo: Alkemist.Repo, views: [layout: {X, :app}])
    assert_raise ArgumentError, ~r/views: was removed.*Alkemist.Theme/, fn -> Config.validate!() end
  end

  test "invalid values raise" do
    put_config(:alkemist, repo: Alkemist.Repo, csv: [separator: :pipe])
    assert_raise NimbleOptions.ValidationError, fn -> Config.csv() end
  end

  test "repo is required" do
    put_config(:other_app, title: "Other")

    assert_raise NimbleOptions.ValidationError, ~r/required :repo option not found/, fn ->
      Config.repo(:other_app)
    end
  end

  test "configuration is per otp_app" do
    put_config(:other_app, repo: Other.Repo, title: "Other")
    assert Config.repo(:other_app) == Other.Repo
    assert Config.get(:title, :other_app) == "Other"
    assert Config.repo(:alkemist) == Alkemist.Repo
    assert Config.get(:title) == "Alkemist"
  end

  test "values are memoised until reset" do
    put_config(:other_app, repo: Other.Repo)
    assert Config.repo(:other_app) == Other.Repo
    Application.put_env(:other_app, Alkemist, repo: Changed.Repo)
    assert Config.repo(:other_app) == Other.Repo
    Config.reset(:other_app)
    assert Config.repo(:other_app) == Changed.Repo
  end
end
