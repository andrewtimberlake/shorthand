if Code.ensure_loaded?(Credo.Check) do
  defmodule Shorthand.Check.Refactor.ShortenMaps do
    @moduledoc """
    Credo check that prefers Shorthand map syntax for atom-key and string-key maps.

    Enable in `.credo.exs`:

        {Shorthand.Check.Refactor.ShortenMaps, []}

    Pair with `Shorthand.Quokka.ShortenMaps` to auto-rewrite on `mix format`.
    """

    use Credo.Check,
      id: "SHORTHAND0001",
      category: :refactor,
      base_priority: :normal,
      explanations: [
        check: """
        Prefer Shorthand map syntax for atom-key and string-key maps.

            %{foo: foo, bar: :baz}
            %{"foo" => foo, "bar" => :baz}

        should be written as:

            m(foo, bar: :baz)
            sm(foo, bar: :baz)

        Structs (`%Mod{}`) are ignored — use `st/2` for those.

        ### Enable in `.credo.exs`:

            {Shorthand.Check.Refactor.ShortenMaps, []}

        Pair with `Shorthand.Quokka.ShortenMaps` to auto-rewrite on `mix format`.
        """
      ],
      exit_status: 0

    alias Shorthand.Maps

    @doc false
    def run(source_file, params \\ []) do
      issue_meta = IssueMeta.for(source_file, params)

      Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
    end

    # Struct AST is `{:%, _, [name, {:%{}, _, pairs}]}`. Rewrite the inner map
    # node so it is not treated as a shorten-able map, while still walking field
    # values (which may contain nested maps).
    defp traverse({:%, meta, [name, {:%{}, map_meta, pairs}]}, issues, _issue_meta)
         when is_list(pairs) do
      {{:%, meta, [name, {:__block__, map_meta, pairs}]}, issues}
    end

    defp traverse({:%{}, meta, pairs} = ast, issues, issue_meta) when is_list(pairs) do
      case Maps.suggest(ast) do
        nil ->
          {ast, issues}

        shortened ->
          issue =
            format_issue(
              issue_meta,
              message: "Use shorthand: #{shortened}",
              trigger: "%{",
              line_no: meta[:line],
              column: meta[:column]
            )

          {ast, [issue | issues]}
      end
    end

    defp traverse(ast, issues, _issue_meta), do: {ast, issues}
  end
end
