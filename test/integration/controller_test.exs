defmodule Alkemist.Integration.ControllerTest do
  use Alkemist.IntegrationCase, async: true
  @moduletag :integration
  import Wallaby.Query

  describe "index" do
    test "it renders default columns", %{session: session} do
      visit(session, "/posts")

      session
      |> find(css("table.index-table > thead > tr"), fn t ->
        assert has?(t, css("th", count: 6))
      end)
    end
  end
end
