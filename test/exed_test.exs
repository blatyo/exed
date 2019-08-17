defmodule ExedTest do
  use ExUnit.Case
  doctest Exed

  test "greets the world" do
    assert Exed.hello() == :world
  end
end
