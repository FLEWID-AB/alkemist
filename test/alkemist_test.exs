defmodule AlkemistTest do
  use ExUnit.Case
  doctest Alkemist

  test "it creates custom controller module" do
    assert Code.ensure_compiled?(TestAlkemist.Alkemist.Controller)
  end

  test "it has runtime configuration" do
    assert TestAlkemist.Alkemist.config(:repo)
  end
end
