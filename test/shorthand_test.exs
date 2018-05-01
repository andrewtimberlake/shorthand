defmodule ShorthandTest do
  use ExUnit.Case
  import Shorthand
  doctest Shorthand

  defmodule TestModule do
    def test_map_func(m(a, b)) do
      kw(a, b)
    end

    def test_string_map_func(sm(a, b)) do
      kw(a, b)
    end

    def index(_conn, sm(model: sm(a, b) = params)) do
      kw(params, a, b)
    end
  end

  describe "function arguments" do
    test "function with map arguments" do
      assert TestModule.test_map_func(%{a: 1, b: 2}) == [a: 1, b: 2]
    end

    test "function with string key map arguments" do
      assert TestModule.test_string_map_func(%{"a" => 1, "b" => 2}) == [a: 1, b: 2]
    end

    test "phoenix style action functions" do
      assert TestModule.index(nil, %{"model" => %{"a" => 1, "b" => 2, "c" => 3}}) == [
               params: %{"a" => 1, "b" => 2, "c" => 3},
               a: 1,
               b: 2
             ]
    end
  end

  describe "m" do
    test "with a single keyword argument" do
      assert m(a: nil) == %{a: nil}
      assert m(a: 1) == %{a: 1}
    end
  end

  describe "sm" do
    test "with a single keyword argument" do
      assert sm(a: nil) == %{"a" => nil}
      assert sm(a: 1) == %{"a" => 1}
    end
  end
end
