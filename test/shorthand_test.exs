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

    test "with nested maps" do
      assert m(a: m(b: 1)) == %{a: %{b: 1}}
    end

    test "with assigned map key" do
      assert m(foo, m(b) = bar) = %{foo: :foo, bar: %{b: 1}}
      assert foo == :foo
      assert bar == %{b: 1}
      assert b == 1
    end

    test "with assigned map key and other keys" do
      assert m(foo, m(b) = bar, baz: bz) = %{foo: :foo, bar: %{b: 1}, baz: 3}
      assert foo == :foo
      assert bar == %{b: 1}
      assert b == 1
      assert bz == 3
    end

    test "with assigned map key and other keys (opposite way around)" do
      assert m(foo, bar = m(b), baz: bz) = %{foo: :foo, bar: %{b: 1}, baz: 3}
      assert foo == :foo
      assert bar == %{b: 1}
      assert b == 1
      assert bz == 3
    end
  end

  describe "sm" do
    test "with a single keyword argument" do
      assert sm(a: nil) == %{"a" => nil}
      assert sm(a: 1) == %{"a" => 1}
    end
  end

  describe "st" do
    defmodule TestStruct do
      defstruct a: 1, b: 2, foo: nil, bar: nil, baz: nil
    end

    test "with no argument" do
      assert st(TestStruct) == %TestStruct{}
    end

    test "with a single keyword argument" do
      assert st(TestStruct, a: nil) == %TestStruct{a: nil}
      assert st(TestStruct, a: 1) == %TestStruct{a: 1}
    end

    test "with nested maps" do
      assert st(TestStruct, a: st(TestStruct, b: 1)) == %TestStruct{a: %TestStruct{b: 1}}
    end

    test "with assigned map key" do
      assert st(TestStruct, foo, st(TestStruct, b) = bar) = %TestStruct{
               foo: :foo,
               bar: %TestStruct{b: 1}
             }

      assert foo == :foo
      assert bar == %TestStruct{b: 1}
      assert b == 1
    end

    test "with assigned map key and other keys" do
      assert st(TestStruct, foo, st(TestStruct, b) = bar, baz: bz) = %TestStruct{
               foo: :foo,
               bar: %TestStruct{b: 1},
               baz: 3
             }

      assert foo == :foo
      assert bar == %TestStruct{b: 1}
      assert b == 1
      assert bz == 3
    end

    test "with assigned map key and other keys (opposite way around)" do
      assert st(TestStruct, foo, bar = st(TestStruct, b), baz: bz) = %TestStruct{
               foo: :foo,
               bar: %TestStruct{b: 1},
               baz: 3
             }

      assert foo == :foo
      assert bar == %TestStruct{b: 1}
      assert b == 1
      assert bz == 3
    end

    test "with matching" do
      a = 4
      foo = :bar
      assert st(TestStruct, ^a, ^foo) = %TestStruct{a: 4, foo: :bar}
      assert st(TestStruct, ^a, _b, ^foo) = %TestStruct{a: 4, foo: :bar}
      assert st(TestStruct, ^a, _b, ^foo, baz: bz) = %TestStruct{a: 4, foo: :bar, baz: 42}
      assert bz == 42
    end
  end
end
