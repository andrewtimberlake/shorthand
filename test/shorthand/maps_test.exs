defmodule Shorthand.MapsTest do
  use ExUnit.Case, async: true

  alias Shorthand.Maps

  describe "suggest/1" do
    test "suggests m/1 for atom-key maps" do
      assert suggest("%{foo: foo}") == "m(foo)"
      assert suggest("%{foo: foo, bar: :baz}") == "m(foo, bar: :baz)"
      assert suggest("%{foo: foo, bar: bar}") == "m(foo, bar)"
      assert suggest("%{foo: ^foo, bar: _bar}") == "m(^foo, _bar)"
    end

    test "suggests sm/1 for string-key maps" do
      assert suggest(~S(%{"foo" => foo})) == "sm(foo)"
      assert suggest(~S(%{"foo" => foo, "bar" => :baz})) == "sm(foo, bar: :baz)"
      assert suggest(~S(%{"foo" => foo, "bar" => bar})) == "sm(foo, bar)"
      assert suggest(~S(%{"foo" => ^foo, "bar" => _bar})) == "sm(^foo, _bar)"
    end

    test "returns nil when nothing can be shortened" do
      assert suggest("%{}") == nil
      assert suggest("%{foo: :bar}") == nil
      assert suggest(~S(%{"foo" => :bar})) == nil
      mixed = {:%{}, [], [{:foo, {:foo, [], nil}}, {"bar", {:bar, [], nil}}]}
      assert Maps.suggest(mixed) == nil
      assert suggest(~S(%{"user-id" => id})) == nil
      assert suggest("%{map | foo: foo}") == nil
    end
  end

  describe "rewrite/1" do
    test "rewrites atom-key maps to m/1" do
      assert {:ok, ast} = Maps.rewrite(ast("%{foo: foo, bar: :baz}"))
      assert Macro.to_string(ast) == "m(foo, bar: :baz)"
    end

    test "rewrites string-key maps to sm/1" do
      assert {:ok, ast} = Maps.rewrite(ast(~S(%{"foo" => foo, "bar" => :baz})))
      assert Macro.to_string(ast) == "sm(foo, bar: :baz)"
    end

    test "returns error when nothing can be shortened" do
      assert Maps.rewrite(ast("%{foo: :bar}")) == :error
      assert Maps.rewrite(ast(~S(%{"user-id" => id}))) == :error
    end
  end

  describe "imports_shorthand?/1" do
    test "detects import Shorthand" do
      source = """
      defmodule Example do
        import Shorthand
        def go(foo), do: m(foo)
      end
      """

      assert Maps.imports_shorthand?(ast(source))
    end

    test "returns false when Shorthand is not imported" do
      source = """
      defmodule Example do
        def go(foo), do: %{foo: foo}
      end
      """

      refute Maps.imports_shorthand?(ast(source))
    end
  end

  defp ast(source), do: Code.string_to_quoted!(source)

  defp suggest(source) do
    {_ast, result} =
      Macro.prewalk(ast(source), nil, fn
        {:%{}, _, _} = node, nil -> {node, Maps.suggest(node)}
        node, acc -> {node, acc}
      end)

    result
  end
end
