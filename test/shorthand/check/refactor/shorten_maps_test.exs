defmodule Shorthand.Check.Refactor.ShortenMapsTest do
  use ExUnit.Case, async: true

  @moduletag :credo

  if Code.ensure_loaded?(Credo.Check) and
       Code.ensure_loaded?(Shorthand.Check.Refactor.ShortenMaps) do
    alias Shorthand.Check.Refactor.ShortenMaps

    setup_all do
      {:ok, _} = Application.ensure_all_started(:credo)
      :ok
    end

    describe "quote blocks" do
      test "does not flag maps inside quote" do
        source = """
        defmodule Example do
          def go(foo) do
            quote do
              %{foo: foo}
            end
          end
        end
        """

        assert issues(source) == []
      end

      test "still flags maps outside quote in the same module" do
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

        assert [%{message: "Use shorthand: m(foo)"}] = issues(source)
      end
    end

    defp issues(source) do
      source
      |> Credo.Test.SourceFiles.to_source_file()
      |> ShortenMaps.run()
    end
  end
end
