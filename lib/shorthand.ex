defmodule Shorthand do
  @moduledoc """
  Convenience macros to eliminate laborious typing. Provides macros for short map, string keyed map, keyword lists, and structs (ES6 like style)

  ## Examples:
  These examples use variable arguments (default is 10, see configuration below)

  Instead of `%{one: one, two: two, three: three}`, you can type `m(one, two, three)`

  Instead of `my_func(one: one, two: two, three: three)`, you can type `my_func(kw(one, two, three))`

  Instead of `%MyStruct(one: one, two: two, three: three)`, you can type `st(MyStruct, one, two, three)`

  ### Without variable arguemnts,
  Instead of `%{one: one, two: two, three: three}`, you can type `m([one, two, three])`

  Instead of `my_func(one: one, two: two, three: three)`, you can type `my_func(kw([one, two, three]))`

  Instead of `%MyStruct(one: one, two: two, three: three)`, you can type `bulid_struct(MyStruct, [one, two, three])`

  ## Configuration

  For the convenience of `m(a, b, c, d, e, f, g, h, i, j)` instead of `m([a, b, c, d, e, f, g, h, i, j])` `Shorthand` generates multiple copies of each macro like m/1, m/2, m/3, …, m/10. You can configure how many of these "variable argument" macros are generated.

      config :shorthand,
        variable_args: 10 # false to remove variable arguemnts


  ## Usage

  You can import the `Shorthand` module and call each macro

      defmodule MyModule do
        import Shorthand

        def my_func(m(a, b)) do
          kw(a, b)
        end
      end

  or you can require the module and prefix calls with the module name (example uses a module alias to keep the typing low

      defmodule MyModule do
        require Shorthand, as: S

        def my_func(S.m(a, b)) do
          S.kw(a, b)
        end
      end

  ## Phoenix Examples
      defmodule MyController do
        # ...

        def index(conn, sm(id)) do
          model = Repo.get(MyModel, id)
          # ...
        end

        def create(conn, sm(my_model: sm(first_name, last_name) = params)) do
          changeset = MyModel.changeset(%MyModel{}, params) # params contains all form fields, not just first_name and last_name
          # ...
          conn
          |> put_flash(:notice, "User \#{first_name} \#{last_name} was created successfully")
          # ...
        end
      end
  """

  @doc ~S"""
  Builds a map where the keys and values have the same name

  ## Example:

      iex> a = 1
      iex> b = 2
      iex> m(a, b)
      %{a: 1, b: 2}

  ## Example:

      iex> a = 1
      iex> c = 2
      iex> m(a, b: m(c), d: nil)
      %{a: 1, b: %{c: 2}, d: nil}

  ## Example:

      iex> a = 1
      iex> m(^a, _b, c) = %{a: 1, b: 3, c: 2}
      iex> c
      2
      iex> match?(m(^a), %{a: 2})
      false

  ## Example:

      iex> m(model: m(a, b) = params) = %{model: %{a: 1, b: 2, c: 3, d: 4}}
      iex> params
      %{a: 1, b: 2, c: 3, d: 4}
      iex> a
      1
      iex> b
      2

  ## Example:

      iex> m(m(a, b) = model) = %{model: %{a: 1, b: 2, c: 3, d: 4}}
      iex> model
      %{a: 1, b: 2, c: 3, d: 4}
      iex> a
      1
      iex> b
      2
  """
  defmacro m([_ | _] = args) do
    build_map(args, :atom)
  end

  @doc ~S"""
  Builds a map where the string keys and values have the same name

  ## Example:

      iex> a = 1
      iex> b = 2
      iex> sm(a, b)
      %{"a" => 1, "b" => 2}

  ## Example:

      iex> a = 1
      iex> b = 2
      iex> sm(a, other: sm(b))
      %{"a" => 1, "other" => %{"b" => 2}}

  ## Example:

      iex> a = 1
      iex> sm(^a, _b, c) = %{"a" => 1, "b" => 3, "c" => 2}
      iex> c
      2
      iex> match?(sm(^a), %{"a" => 2})
      false

  ## Example:

      iex> sm(model: sm(a, b) = params) = %{"model" => %{"a" => 1, "b" => 2, "c" => 3, "d" => 4}}
      iex> params
      %{"a" => 1, "b" => 2, "c" => 3, "d" => 4}
      iex> a
      1
      iex> b
      2

  ## Example:

      iex> sm(sm(a, b) = model) = %{"model" => %{"a" => 1, "b" => 2, "c" => 3, "d" => 4}}
      iex> model
      %{"a" => 1, "b" => 2, "c" => 3, "d" => 4}
      iex> a
      1
      iex> b
      2
  """
  defmacro sm([_ | _] = args) do
    build_map(args, :string)
  end

  @doc ~S"""
  Builds a keyword list where the keys and value arguments are the same name

  ## Example:

      iex> a = 1
      iex> b = 2
      iex> c = 3
      iex> kw(a, b, c)
      [a: 1, b: 2, c: 3]

  ## Examples

      iex> c = 3
      iex> kw(a, _b, ^c) = [a: 1, b: 3, c: 3]
      iex> a
      1
      iex> match?(kw(^a), [a: 1])
      true
  """
  defmacro kw([_ | _] = args) do
    build_keywords(args)
  end

  @doc ~S"""
  Builds a struct where the field names are the same as the arguments supplied

  ## Example:

      iex> scheme = "https"
      iex> host = "elixir-lang.org"
      iex> path = "/docs.html"
      iex> st(URI, scheme, host, path)
      %URI{scheme: "https", host: "elixir-lang.org", path: "/docs.html"}
  """
  defmacro st(module, [_ | _] = args) do
    build_struct_from_list(module, args)
  end

  variable_args = Application.compile_env(:shorthand, :variable_args, 10)

  if variable_args do
    1..variable_args
    |> Enum.each(fn i ->
      args = 1..i |> Enum.map(fn i -> {:"arg#{i}", [], nil} end)

      defmacro m(unquote_splicing(args)) do
        build_map(unquote(args), :atom)
      end

      defmacro sm(unquote_splicing(args)) do
        build_map(unquote(args), :string)
      end

      defmacro kw(unquote_splicing(args)) do
        build_keywords(unquote(args))
      end

      defmacro st(module, unquote_splicing(args)) do
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
      # m(a: 1, ...)
      {name, value} ->
        {map_key(name, type), value}

      # m(^a)
      {:^, context1, [{name, context2, nil}]} ->
        {map_key(name, type), {:^, context1, [{name, context2, nil}]}}

      # m(a)
      {name, context, nil} ->
        {map_key(variable_name(name), type), {name, context, nil}}

      # m(a, b: m(c))
      keyword_list when is_list(keyword_list) ->
        keyword_list
        |> Enum.map(fn {key, value} -> {map_key(key, type), value} end)

      # m(m(b) = bar)
      {:=, context, [left, {name, _context2, nil} = right]} ->
        [{map_key(name, type), {:=, context, [left, right]}}]

      # m(bar = m(b))
      {:=, context, [{name, _context2, nil} = left, right]} ->
        [{map_key(name, type), {:=, context, [left, right]}}]

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
