defmodule ExProtohackersTest do
  use ExUnit.Case, async: true
  doctest ExProtohackers

  test "greets the world" do
    assert ExProtohackers.hello() == :world
  end
end
