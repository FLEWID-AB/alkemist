defmodule Alkemist.ConfigTest do
  use ExUnit.Case, async: true
  alias Alkemist.Config
  alias Alkemist.TestImplementation, as: Implementation

  test "uses Repo from config" do
    assert Alkemist.Repo == Config.repo(Implementation)
  end

  test "router helpers returns value from config" do
    assert Implementation.config(:router_helpers) == Config.router_helpers(Implementation)
  end

  test "layout returns alkemist default" do
    assert {Alkemist.LayoutView, "app.html"} == Config.layout(Implementation)
  end

  test "route prefix returns value form config or nil" do
    assert nil == Config.route_prefix(Implementation)
  end

  test "search provider defaults to alkemist" do
    assert Alkemist.Query.Search == Config.search_provider(Implementation)
  end

  test "pagination provider defaults to alkemist" do
    assert Alkemist.Query.Paginate == Config.pagination_provider(Implementation)
  end

end
