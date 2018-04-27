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
        keywords: :k,
        build_struct: :s,
        variable_args: 10 # false to remove variable arguemnts
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
  map_name = Application.get_env(:shorthand, :map, :m)

  defmacro unquote(map_name)([_ | _] = args) do
    build_map(args)
  end

  @doc ~S"""
  Builds a keyword list where the keys and value arguments are the same name

  ## Example:

      iex> a = 1
      iex> b = 2
      iex> c = 3
      iex> keywords(a, b, c)
      [a: 1, b: 2, c: 3]
  """
  keywords_name = Application.get_env(:shorthand, :keywords, :k)

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
        build_map(unquote(args))
      end

      defmacro keywords(unquote_splicing(args)) do
        build_keywords(unquote(args))
      end

      defmacro build_struct(module, unquote_splicing(args)) do
        build_struct_from_list(module, unquote(args))
      end
    end)
  end

  defp build_map(args) do
    # IO.inspect(args, label: "args")

    map_args =
      args
      |> Enum.map(fn
        {:^, context, [{name, context, nil}]} ->
          {name, {:^, context, [{name, context, nil}]}}

        {name, context, nil} ->
          {variable_name(name), {name, context, nil}}

        keyword_list when is_list(keyword_list) ->
          keyword_list

          # other ->
          #   IO.inspect(other, label: "other")
      end)
      |> List.flatten()

    {:%{}, [], map_args}
  end

  defp build_keywords(args) do
    # IO.inspect(args, label: "args")

    keyword_list =
      args
      |> Enum.map(fn {name, context, nil} ->
        {name, {name, context, nil}}
      end)

    quote do
      unquote(keyword_list)
    end
  end

  defp build_struct_from_list(module, args) do
    quote do
      struct(unquote(module), unquote(build_keywords(args)))
    end
  end

  defp variable_name(name) when is_atom(name), do: variable_name(Atom.to_string(name))
  defp variable_name(<<"_", name::binary>>), do: variable_name(name)
  defp variable_name(name), do: String.to_atom(name)
end
