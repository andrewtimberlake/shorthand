defmodule Shorthand.Quokka.ShortenMapsTest do
  use ExUnit.Case, async: true

  @moduletag :quokka

  if Code.ensure_loaded?(Quokka.Plugin) and Code.ensure_loaded?(Shorthand.Quokka.ShortenMaps) do
    alias Quokka.Zipper
    alias Shorthand.Quokka.ShortenMaps

    describe "quote blocks" do
      test "does not rewrite maps inside quote" do
        source = """
        defmodule Example do
          def go(foo) do
            quote do
              %{foo: foo}
            end
          end
        end
        """

        assert Macro.to_string(rewrite(source)) =~ "%{foo: foo}"
        refute Macro.to_string(rewrite(source)) =~ "m(foo)"
      end

      test "still rewrites maps outside quote in the same module" do
        source = """
        defmodule Example do
          def quoted(foo) do
            quote do
              %{foo: foo}
            end
          end

          def plain(foo), do: %{foo: foo}
        end
        """

        rewritten = Macro.to_string(rewrite(source))

        assert rewritten =~ "%{foo: foo}"
        assert rewritten =~ "m(foo)"
        assert rewritten =~ "import Shorthand"
      end
    end

    describe "nested modules" do
      test "adds import to the outer module when only the nested module already imports" do
        source = """
        defmodule Example do
          def child_spec(id) do
            %{id: id, type: :worker}
          end

          defmodule Server do
            import Shorthand
            def init(root), do: {:ok, m(root)}
          end
        end
        """

        rewritten = Macro.to_string(rewrite(source))

        assert rewritten =~ "m(id, type: :worker)"
        assert rewritten =~ ~r/defmodule Example do\s+import Shorthand/
      end
    end

    describe "import formatting" do
      test "inserts a blank line between import and following aliases" do
        source = """
        defmodule Example do
          @moduledoc "docs"

          alias Foo

          def go(foo), do: %{foo: foo}
        end
        """

        {ast, comments} = Quokka.string_to_ast(source, "test.ex")
        Quokka.Config.set([])
        {ast, comments} = Quokka.style({ast, comments}, "test.ex", [])

        zipper = Zipper.zip(ast)

        {:skip, zipper, _} =
          ShortenMaps.run(zipper, %{comments: comments, file: "test.ex", plugin_opts: []})

        formatted = Quokka.ast_to_string(Zipper.node(zipper), comments, [])

        assert formatted =~ """
                 import Shorthand

                 alias Foo
               """
      end
    end

    defp rewrite(source) do
      zipper = source |> Code.string_to_quoted!() |> Zipper.zip()
      {:skip, zipper, _ctx} = ShortenMaps.run(zipper, %{})
      Zipper.node(zipper)
    end
  end
end
