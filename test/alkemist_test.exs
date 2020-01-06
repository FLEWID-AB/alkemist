defmodule AlkemistTest do
  use ExUnit.Case
  doctest Alkemist

  test "it creates custom controller module" do
    assert Code.ensure_compiled?(Alkemist.TestImplementation.Controller)
  end

  test "it has runtime configuration" do
    assert Alkemist.TestImplementation.config(:repo)
  end
end
