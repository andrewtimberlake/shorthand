# Shorthand

![](https://github.com/andrewtimberlake/shorthand/actions/workflows/elixir.yml/badge.svg)

Convenience macros to eliminate laborious typing. Provides macros for short map, string keyed map, keyword lists, and structs (ES6 like style)

## Installation

Add `shorthand` as a dependency in your project in your `mix.exs` file:

```elixir
def deps do
  [
    {:shorthand, "~> 1.0.0"}
  ]
end
```

## Usage

See the [docs](https://hexdocs.pm/shorthand) for more examples

```elixir
defmodule MyModule do
  import Shorthand

  defstruct name: nil, age: nil

  def my_func(m(name, age, _height)) do
    st(MyModule, name, age)
  end
end
```
