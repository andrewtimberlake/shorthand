defmodule Shorthand do
  @moduledoc """
  Convenience macros to eliminate laborious typing.

  ## Examples:
  These examples use variable arguments (default is 10, see configuration below)

  Instead of `%{one: one, two: two, three: three}`, you can type `map(one, two, three)`

  Instead of `my_func(one: one, two: two, three: three)`, you can type `my_func(keywords(one, two, three))`

  Instead of `%MyStruct(one: one, two: two, three: three)`, you can type `bulid_struct(MyStruct, one, two, three)`

  ### Without variable arguemnts,
  Instead of `%{one: one, two: two, three: three}`, you can type `map([one, two, three])`

  Instead of `my_func(one: one, two: two, three: three)`, you can type `my_func(keywords([one, two, three]))`

  Instead of `%MyStruct(one: one, two: two, three: three)`, you can type `bulid_struct(MyStruct, [one, two, three])`

  ## Configuration

  Because Shorthand is about convenience, the macros can be configured

      config :shorthand,
        map: :m,
        str_map: :sm,
        keywords: :k,
        build_struct: :s,
        variable_args: 10 # false to remove variable arguemnts

  Then you can use them as:

      m(a, _b, ^c) == %{a: a, b: _b, c: ^c}
      sm(a, _b, ^c) == %{"a" => a, "b" => _b, "c" => ^c}
      k(a, b, c) == [a: a, b: b, c: c]
      s(Date, year, month, day) == %Date{year: year, month: month, day: day}
  """

  @doc ~S"""
  Builds a map where the keys and values have the same name

  ## Example:

      iex> a = 1
      iex> b = 2
      iex> map(a, b)
      %{a: 1, b: 2}

  ## Example:

      iex> a = 1
      iex> b = 2
      iex> map(a, other: map(b))
      %{a: 1, other: %{b: 2}}

  ## Example:

      iex> a = 1
      iex> map(^a, _b, c) = %{a: 1, b: 3, c: 2}
      iex> c
      2
      iex> match?(map(^a), %{a: 2})
      false
  """
  map_name = Application.get_env(:shorthand, :map, :map)

  defmacro unquote(map_name)([_ | _] = args) do
    build_map(args, :atom)
  end

  @doc ~S"""
  Builds a map where the string keys and values have the same name

  ## Example:

      iex> a = 1
      iex> b = 2
      iex> str_map(a, b)
      %{"a" => 1, "b" => 2}

  ## Example:

      iex> a = 1
      iex> b = 2
      iex> str_map(a, other: str_map(b))
      %{"a" => 1, "other" => %{"b" => 2}}

  ## Example:

      iex> a = 1
      iex> str_map(^a, _b, c) = %{"a" => 1, "b" => 3, "c" => 2}
      iex> c
      2
      iex> match?(str_map(^a), %{"a" => 2})
      false
  """
  str_map_name = Application.get_env(:shorthand, :str_map, :str_map)

  defmacro unquote(str_map_name)([_ | _] = args) do
    build_map(args, :string)
  end

  @doc ~S"""
  Builds a keyword list where the keys and value arguments are the same name

  ## Example:

      iex> a = 1
      iex> b = 2
      iex> c = 3
      iex> keywords(a, b, c)
      [a: 1, b: 2, c: 3]

  ## Examples

      iex> c = 3
      iex> keywords(a, _b, ^c) = [a: 1, b: 3, c: 3]
      iex> a
      1
      iex> match?(keywords(^a), [a: 2])
      false
  """
  keywords_name = Application.get_env(:shorthand, :keywords, :keywords)

  defmacro unquote(keywords_name)([_ | _] = args) do
    build_keywords(args)
  end

  @doc ~S"""
  Builds a struct where the field names are the same as the arguments supplied

  ## Example:

      iex> year = 2018
      iex> month = 4
      iex> day = 27
      iex> build_struct(Date, year, month, day)
      %Date{year: 2018, month: 4, day: 27}
  """
  struct_name = Application.get_env(:shorthand, :build_struct, :build_struct)

  defmacro unquote(struct_name)(module, [_ | _] = args) do
    build_struct_from_list(module, args)
  end

  variable_args = Application.get_env(:shorthand, :variable_args, 10)

  if variable_args do
    1..variable_args
    |> Enum.each(fn i ->
      args = 1..i |> Enum.map(fn i -> {:"arg#{i}", [], nil} end)

      defmacro map(unquote_splicing(args)) do
        build_map(unquote(args), :atom)
      end

      defmacro str_map(unquote_splicing(args)) do
        build_map(unquote(args), :string)
      end

      defmacro keywords(unquote_splicing(args)) do
        build_keywords(unquote(args))
      end

      defmacro build_struct(module, unquote_splicing(args)) do
        build_struct_from_list(module, unquote(args))
      end
    end)
  end

  defp build_map(args, type) do
    {:%{}, [], parse_args(args, type)}
  end

  defp build_keywords(args) do
    quote do
      unquote(parse_args(args, :atom))
    end
  end

  defp parse_args(args, type) do
    # IO.inspect(args, label: "args")

    args
    |> Enum.map(fn
      {:^, context, [{name, context, nil}]} ->
        {map_key(name, type), {:^, context, [{name, context, nil}]}}

      {name, context, nil} ->
        {map_key(variable_name(name), type), {name, context, nil}}

      keyword_list when is_list(keyword_list) ->
        keyword_list
        |> Enum.map(fn {key, value} -> {map_key(key, type), value} end)

        # other ->
        #   IO.inspect(other, label: "other")
    end)
    |> List.flatten()
  end

  defp build_struct_from_list(module, args) do
    quote do
      struct(unquote(module), unquote(build_keywords(args)))
    end
  end

  defp map_key(key, :atom) when is_atom(key), do: key
  defp map_key(key, :string) when is_atom(key), do: to_string(key)

  defp variable_name(name) when is_atom(name), do: variable_name(Atom.to_string(name))
  defp variable_name(<<"_", name::binary>>), do: variable_name(name)
  defp variable_name(name), do: String.to_atom(name)
end
