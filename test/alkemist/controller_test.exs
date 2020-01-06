defmodule Alkemist.ControllerTest do
  use ExUnit.Case, async: true

  defmodule ControllerWithDefaults do
    use Phoenix.Controller
    use Alkemist.TestImplementation.Controller, resource: Alkemist.Post
  end


  describe "default implementation" do
    test "it creates default methods" do
      methods = ControllerWithDefaults.__info__(:functions)

      assert Enum.member?(methods, {:index, 2})
      assert Enum.member?(methods, {:show, 2})
      assert Enum.member?(methods, {:edit, 2})
      assert Enum.member?(methods, {:create, 2})
      assert Enum.member?(methods, {:update, 2})
      assert Enum.member?(methods, {:delete, 2})
    end

  end
end
