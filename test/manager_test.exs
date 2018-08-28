defmodule ManagerTest do
  use ExUnit.Case
  doctest Manager

  test "greets the world" do
    assert Manager.hello() == :world
  end
end
