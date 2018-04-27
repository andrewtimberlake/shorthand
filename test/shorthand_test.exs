defmodule ShorthandTest do
  use ExUnit.Case
  import Shorthand
  doctest Shorthand

  describe "map" do
    test "with a single keyword argument" do
      assert map(a: nil) == %{a: nil}
      assert map(a: 1) == %{a: 1}
    end
  end

  describe "str_map" do
    test "with a single keyword argument" do
      assert str_map(a: nil) == %{"a" => nil}
      assert str_map(a: 1) == %{"a" => 1}
    end
  end
end
