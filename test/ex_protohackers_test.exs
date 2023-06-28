defmodule ExProtohackersTest do
  use ExUnit.Case
  doctest ExProtohackers

  test "greets the world" do
    assert ExProtohackers.hello() == :world
  end
end
