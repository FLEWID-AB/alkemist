defmodule Alkemist.ConfigTest do
  use ExUnit.Case, async: true
  alias Alkemist.Config

  @config Application.get_env(:alkemist, Alkemist, [])

  test "uses Repo from config" do
    assert @config[:repo] == Config.repo()
  end

  test "router helpers returns value from config" do
    assert @config[:router_helpers] == Config.router_helpers()
  end

  test "layout returns alkemist default" do
    assert {Alkemist.LayoutView, "app.html"} == Config.layout()
  end

  test "authorization provider returns default" do
    assert Alkemist.Authorization == Config.authorization_provider()
  end

  test "route prefix returns value form config or nil" do
    assert nil == Config.route_prefix()
  end

  test "search provider defaults to alkemist" do
    assert Alkemist.Query.Search == Config.search_provider()
  end

  test "pagination provider defaults to alkemist" do
    assert Alkemist.Query.Paginate == Config.pagination_provider()
  end

end
