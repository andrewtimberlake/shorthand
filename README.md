# Shorthand

Convenience macros to eliminate laborious typing. Provides macros for short map, string key'd map, keyword lists, and structs (ES6 like style)

## Installation

Add `shorthand` as a dependency in your project in your `mix.exs` file:

```elixir
def deps do
  [
    {:shorthand, "~> 0.0.3"}
  ]
end
```

## Usage

See the [docs](https://hexdocs.pm/shorthand) for more examples

```elixir
defmodule MyModule do
  import Shorthand

  defstruct name: nil, age: nil

  def my_func(map(name, age, _height)) do
    build_struct(MyModule, name, age)
  end
end
```