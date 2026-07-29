if Code.ensure_loaded?(Quokka.Plugin) do
  defmodule Shorthand.Quokka.ShortenMaps do
    @moduledoc """
    Quokka plugin that rewrites shortenable maps to `m(...)` / `sm(...)`.

    When a rewrite happens in a module that does not yet `import Shorthand`,
    the import is added automatically.

    Structs and maps inside `quote` blocks are left unchanged — Shorthand
    macros cannot appear in quoted AST.

    Enable in `.formatter.exs`:

        [
          plugins: [Quokka],
          quokka: [
            plugins: [Shorthand.Quokka.ShortenMaps]
          ]
        ]
    """

    use Quokka.Plugin, description: "Rewrites maps to Shorthand m(...)/sm(...)"

    alias Quokka.Zipper
    alias Shorthand.Maps

    @impl Quokka.Style
    def run({{:defmodule, _, _} = node, _meta} = zipper, ctx) do
      rewritten = transform_module(node)

      if rewritten != node do
        {:skip, Zipper.replace(zipper, rewritten), ctx}
      else
        {:skip, zipper, ctx}
      end
    end

    def run({{:%{}, _meta, pairs}, _zipper_meta} = zipper, ctx) when is_list(pairs) do
      if inside_struct?(zipper) or inside_quote?(zipper) do
        {:cont, zipper, ctx}
      else
        case Maps.rewrite(Zipper.node(zipper)) do
          {:ok, shorthand_ast} -> {:cont, Zipper.replace(zipper, shorthand_ast), ctx}
          :error -> {:cont, zipper, ctx}
        end
      end
    end

    def run(zipper, ctx), do: {:cont, zipper, ctx}

    defp transform_module({:defmodule, meta, [name, [do_clause]]} = node) do
      already_imported? = Maps.imports_shorthand?(node)
      {do_clause, changed?} = rewrite_do_clause(do_clause)

      node = {:defmodule, meta, [name, [do_clause]]}

      cond do
        not changed? -> node
        already_imported? -> node
        true -> add_import(node)
      end
    end

    defp rewrite_do_clause({{:__block__, meta, [:do]}, body}) do
      {body, changed?} = rewrite_ast(body, false)
      {{{:__block__, meta, [:do]}, body}, changed?}
    end

    defp rewrite_do_clause(other) do
      rewrite_ast(other, false)
    end

    defp rewrite_ast({:defmodule, _, _} = node, changed?) do
      rewritten = transform_module(node)
      {rewritten, changed? or rewritten != node}
    end

    # Shorthand macros cannot appear inside quote — leave quoted AST alone.
    defp rewrite_ast({:quote, _, _} = node, changed?), do: {node, changed?}

    defp rewrite_ast({:%, meta, [name, {:%{}, map_meta, pairs}]}, changed?) when is_list(pairs) do
      {pairs, changed?} = rewrite_ast(pairs, changed?)
      {{:%, meta, [name, {:%{}, map_meta, pairs}]}, changed?}
    end

    defp rewrite_ast({:%{}, meta, pairs}, changed?) when is_list(pairs) do
      {pairs, changed?} = rewrite_ast(pairs, changed?)
      node = {:%{}, meta, pairs}

      case Maps.rewrite(node) do
        {:ok, shorthand_ast} -> {shorthand_ast, true}
        :error -> {node, changed?}
      end
    end

    defp rewrite_ast({form, meta, args}, changed?) when is_list(args) do
      {args, changed?} = rewrite_ast(args, changed?)
      {{form, meta, args}, changed?}
    end

    defp rewrite_ast({left, right}, changed?) do
      {left, changed?} = rewrite_ast(left, changed?)
      {right, changed?} = rewrite_ast(right, changed?)
      {{left, right}, changed?}
    end

    defp rewrite_ast(list, changed?) when is_list(list) do
      Enum.map_reduce(list, changed?, &rewrite_ast/2)
    end

    defp rewrite_ast(other, changed?), do: {other, changed?}

    defp add_import({:defmodule, meta, [name, [{{:__block__, do_meta, [:do]}, body}]]}) do
      {:defmodule, meta, [name, [{{:__block__, do_meta, [:do]}, insert_import(body)}]]}
    end

    defp add_import({:defmodule, meta, [name, [{:do, body}]]}) do
      {:defmodule, meta, [name, [do: insert_import(body)]]}
    end

    defp insert_import({:__block__, meta, children}) when is_list(children) do
      {leading, rest} = Enum.split_while(children, &before_alias?/1)
      leading = tighten_trailing_import_newlines(leading)
      {:__block__, meta, leading ++ [import_ast() | rest]}
    end

    defp insert_import(only_child) do
      if before_alias?(only_child) do
        only_child = tighten_trailing_import_newlines([only_child]) |> hd()
        {:__block__, [], [only_child, import_ast()]}
      else
        {:__block__, [], [import_ast(), only_child]}
      end
    end

    # Insert before aliases/requires so Quokka's preferred directive order is preserved:
    # moduledoc → use → import → alias → require
    defp before_alias?({:alias, _, _}), do: false
    defp before_alias?({:require, _, _}), do: false
    defp before_alias?({:import, _, _}), do: true
    defp before_alias?({:use, _, _}), do: true
    defp before_alias?({:@, _, [{:moduledoc, _, _}]}), do: true
    defp before_alias?({:@, _, [{:shortdoc, _, _}]}), do: true
    defp before_alias?({:@, _, [{:behaviour, _, _}]}), do: true
    defp before_alias?(_), do: false

    # Plugins run after ModuleDirectives, so we must emit Quokka-style blank lines ourselves:
    # newlines: 1 within a directive group, newlines: 2 between groups.
    defp tighten_trailing_import_newlines(children) do
      case Enum.split(children, -1) do
        {front, [{:import, meta, args}]} ->
          front ++ [{:import, put_newlines(meta, 1), args}]

        _ ->
          children
      end
    end

    defp import_ast do
      {:import, [end_of_expression: [newlines: 2]], [{:__aliases__, [], [:Shorthand]}]}
    end

    defp put_newlines(meta, newlines) do
      Keyword.update(
        meta,
        :end_of_expression,
        [newlines: newlines],
        &Keyword.put(&1, :newlines, newlines)
      )
    end

    defp inside_struct?(zipper) do
      case Zipper.up(zipper) do
        {{:%, _, _}, _} -> true
        _ -> false
      end
    end

    defp inside_quote?(zipper) do
      case Zipper.up(zipper) do
        nil -> false
        {{:quote, _, _}, _} -> true
        parent -> inside_quote?(parent)
      end
    end
  end
end
