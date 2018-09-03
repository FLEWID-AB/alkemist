defmodule Alkemist.ConfigTest do
  use ExUnit.Case, async: true
  alias Alkemist.Config

  test "repo defaults to nil" do
    assert nil == Config.repo()
  end

  test "router helpers returns value from config" do
    assert AlkemistTest.Router.Helpers == Config.router_helpers()
  end

  test "layout returns alkemist default" do
    assert {Alkemist.LayoutView, "app.html"} == Config.layout()
  end

  test "authorization provider returns default" do
    assert Alkemist.Authorization == Config.authorization_provider()
  end
end
