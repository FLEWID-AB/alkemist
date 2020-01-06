defmodule Alkemist.PlugTest do
  use Alkemist.ConnCase, async: true

  @default_opts [implementation: TestAlkemist.Alkemist, resource: TestAlkemist.Post, controller: TestAlkemist.PostController]
  describe "call/2" do
    test "it assigns options", %{conn: conn} do
      conn = Alkemist.Plug.call(conn, @default_opts)

      assert %{private: private} = conn
      assert Map.get(private, :alkemist_implementation) == @default_opts[:implementation]
      assert Map.get(private, :alkemist_resource) == @default_opts[:resource]
      assert Map.get(private, :alkemist_controller) == @default_opts[:controller]
    end
  end
end
