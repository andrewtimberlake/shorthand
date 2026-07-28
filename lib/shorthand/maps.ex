defmodule Shorthand.Maps do
  @moduledoc false

  @max_shorthand_items Application.compile_env(:shorthand, :variable_args, 10)

  @doc """
  Rewrites a map AST node to `m(...)` or `sm(...)` when it can be shortened.

  Returns `{:ok, shorthand_ast}` or `:error`.
  """
  def rewrite({:%{}, meta, pairs}) when is_list(pairs) do
    case classify_pairs(pairs) do
      nil ->
        :error

      {form, matching, non_matching} ->
        matching_args = Enum.map(matching, fn {:matching, _kind, ast} -> ast end)

        keyword_pairs =
          Enum.map(non_matching, fn {:non_matching, _kind, key, value} ->
            format_keyword(key, value)
          end)

        args =
          if keyword_pairs == [] do
            matching_args
          else
            matching_args ++ [keyword_pairs]
          end

        call_meta = Keyword.take(meta, [:line, :column])
        {:ok, {form, call_meta, args}}
    end
  end

  def rewrite(_), do: :error

  @doc "Returns a string suggestion like `m(foo)` or `sm(foo)`, or nil."
  def suggest({:%{}, _meta, pairs}) when is_list(pairs) do
    case classify_pairs(pairs) do
      nil ->
        nil

      {form, matching, non_matching} ->
        parts =
          Enum.map(matching, fn {:matching, _kind, ast} -> Macro.to_string(ast) end) ++
            Enum.map(non_matching, fn {:non_matching, _kind, key, value} ->
              "#{key}: #{Macro.to_string(value)}"
            end)

        "#{form}(#{Enum.join(parts, ", ")})"
    end
  end

  def suggest(_), do: nil

  @doc "True when the module AST already imports Shorthand."
  def imports_shorthand?(ast) do
    {_, imported?} =
      Macro.prewalk(ast, false, fn
        {:import, _, [{:__aliases__, _, [:Shorthand]} | _]}, _acc ->
          {nil, true}

        node, acc ->
          {node, acc}
      end)

    imported?
  end

  defp classify_pairs(pairs)
       when is_integer(@max_shorthand_items) and length(pairs) > @max_shorthand_items,
       do: nil

  defp classify_pairs([]), do: nil
  defp classify_pairs([{:|, _meta, _args} | _]), do: nil

  defp classify_pairs(pairs) do
    parsed = Enum.map(pairs, &parse_pair/1)

    if Enum.any?(parsed, &(&1 == :invalid)) do
      nil
    else
      kinds =
        parsed
        |> Enum.map(fn
          {:matching, kind, _} -> kind
          {:non_matching, kind, _, _} -> kind
        end)
        |> Enum.uniq()

      {matching, non_matching} =
        Enum.split_with(parsed, fn
          {:matching, _, _} -> true
          {:non_matching, _, _, _} -> false
        end)

      case {kinds, matching} do
        {[:atom], [_ | _]} -> {:m, matching, non_matching}
        {[:string], [_ | _]} -> {:sm, matching, non_matching}
        _ -> nil
      end
    end
  end

  defp parse_pair(pair) do
    with {key, value} <- unwrap_pair(pair),
         {:ok, kind, atom_key} <- key_info(key) do
      classify_value(kind, atom_key, value)
    else
      _ -> :invalid
    end
  end

  defp classify_value(kind, atom_key, {atom_key, _meta, _context} = value) do
    {:matching, kind, value}
  end

  defp classify_value(kind, atom_key, {:^, _meta, [{atom_key, _var_meta, _context}]} = value) do
    {:matching, kind, value}
  end

  defp classify_value(kind, atom_key, {var, _meta, _context} = value) when is_atom(var) do
    if Atom.to_string(var) == "_#{atom_key}" do
      {:matching, kind, value}
    else
      {:non_matching, kind, atom_key, value}
    end
  end

  defp classify_value(kind, atom_key, value) do
    {:non_matching, kind, atom_key, value}
  end

  defp key_info(key) when is_atom(key), do: {:ok, :atom, key}

  defp key_info(key) when is_binary(key) do
    if Regex.match?(~r/^[a-z_][a-zA-Z0-9_]*[?!]?$/, key) do
      {:ok, :string, String.to_atom(key)}
    else
      :error
    end
  end

  defp key_info(_), do: :error

  # Quokka wraps keys as `{:__block__, meta, [key]}`
  defp unwrap_pair({{:__block__, meta, [key]}, value}) when is_list(meta) do
    {key, value}
  end

  defp unwrap_pair({key, value}) when is_atom(key) or is_binary(key), do: {key, value}
  defp unwrap_pair(_), do: :error

  # Keep Quokka-friendly keyword formatting when emitting rewrite AST
  defp format_keyword(key, value) do
    {{:__block__, [format: :keyword], [key]}, value}
  end
end
