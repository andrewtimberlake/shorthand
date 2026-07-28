# Shorthand

![](https://github.com/andrewtimberlake/shorthand/actions/workflows/elixir.yml/badge.svg)

Shorthand provides macros to create or match against maps and keyword lists with atom or string-based keys.

## Installation

Add `shorthand` as a dependency in your project in your `mix.exs` file:

```elixir
def deps do
  [
    {:shorthand, "~> 1.0"}
  ]
end
```

## Usage

Wherever you would use a map literal, you can use the shorthand macros instead, whether in assignment or as a pattern.

`%{conn: conn}` can become `m(conn)`.

`%{params: %{"email" => email, "password" => password}}` can become `m(params: sm(email, password))`.

`%{foo: _foo}` can become `m(_foo)`.

`%{foo: ^foo}` can become `m(^foo)`.

You can specify the variable name for the key you are destructuring along with shorthand keys, but like normal function calls, they work as keyword lists at the end.

`%{foo: foo, bar: bor, baz: qux}` can become `m(foo, bar, baz: qux)`

`%{foo: bar, baz: baz, qux: qux}` would need to become `m(baz, qux, foo: bar)`

See the [docs](https://hexdocs.pm/shorthand) for more examples

## Atom keyed maps

| Shorthand                            | Equivalent Elixir                                         |
| ------------------------------------ | --------------------------------------------------------- |
| `m(foo, bar)`                        | `%{foo: foo, bar: bar}`                                   |
| `m(foo, _bar, ^baz)`                 | `%{foo: foo, bar: _bar, baz: ^baz}`                       |
| `m(foo, bar, baz: m(qux))`           | `%{foo: foo, bar: bar, baz: %{qux: qux}}`                 |
| `m(foo, m(baz) = bar, qux: m(quux))` | `%{foo: foo, bar: %{baz: baz} = bar, qux: %{quux: quux}}` |
| `m(foo, bar = m(baz), qux: m(quux))` | `%{foo: foo, bar: %{baz: baz} = bar, qux: %{quux: quux}}` |

## String keyed maps
| Shorthand                               | Equivalent Elixir                                                             |
| --------------------------------------- | ----------------------------------------------------------------------------- |
| `sm(foo, bar)`                          | `%{"foo" => foo, "bar" => bar}`                                               |
| `sm(foo, _bar, ^baz)`                   | `%{"foo" => foo, "bar" => _bar, "baz" => ^baz}`                               |
| `sm(foo, bar, baz: sm(qux))`            | `%{"foo" => foo, "bar" => bar, "baz" => %{"qux" => qux}}`                     |
| `sm(foo, sm(baz) = bar, qux: sm(quux))` | `%{"foo" => foo, "bar" => %{"baz" => baz} = bar, "qux" => %{"quux" => quux}}` |
| `sm(foo, bar = sm(baz), qux: sm(quux))` | `%{"foo" => foo, "bar" => %{"baz" => baz} = bar, "qux" => %{"quux" => quux}}` |

## Keyword lists

| Shorthand                               | Equivalent Elixir                                      |
| --------------------------------------- | ------------------------------------------------------ |
| `kw(foo, bar)`                          | `[foo: foo, bar: bar]`                                 |
| `kw(foo, _bar, ^baz)`                   | `[foo: foo, bar: _bar, baz: ^baz]`                     |
| `kw(foo, bar, baz: kw(qux))`            | `[foo: foo, bar: bar, baz: [qux: qux]]`                |
| `kw(foo, kw(baz) = bar, qux: kw(quux))` | `[foo: foo, bar: [baz: baz] = bar, qux: [quux: quux]]` |
| `kw(foo, bar = kw(baz), qux: kw(quux))` | `[foo: foo, bar: [baz: baz] = bar, qux: [quux: quux]]` |

## Structs

| Shorthand                                        | Equivalent Elixir                                                 |
| ------------------------------------------------ | ----------------------------------------------------------------- |
| `st(MyStruct, foo, bar)`                         | `%MyStruct{foo: foo, bar: bar}`                                   |
| `st(MyStruct, foo, _bar, ^baz)`                  | `%MyStruct{foo: foo, bar: _bar, baz: ^baz}`                       |
| `st(MyStruct, foo, bar, baz: st(MyStruct, qux))` | `%MyStruct{foo: foo, bar: bar, baz: %MyStruct{qux: qux}}`         |
| `st(MyStruct, foo, m(baz) = bar, qux: m(quux))`  | `%MyStruct{foo: foo, bar: %{baz: baz} = bar, qux: %{quux: quux}}` |
| `st(MyStruct, foo, bar = m(baz), qux: m(quux))`  | `%MyStruct{foo: foo, bar: %{baz: baz} = bar, qux: %{quux: quux}}` |

# Configuration

  For the convenience of `m(a, b, c, d, e, f, g, h, i, j)` instead of `m([a, b, c, d, e, f, g, h, i, j])` 
  `Shorthand` generates multiple copies of each macro like m/1, m/2, m/3, …, m/10. 
  You can configure how many of these "variable argument" macros are generated.

      config :shorthand,
        variable_args: 10 # false to remove variable arguemnts

## Credo & Quokka integration

Shorthand can flag and rewrite map literals automatically.

### Credo

Add the check to `.credo.exs`:

```elixir
{Shorthand.Check.Refactor.ShortenMaps, []}
```

Credo must be available in your project (directly or via another dependency).

### Quokka

Add the plugin to `.formatter.exs`:

```elixir
[
  plugins: [Quokka],
  quokka: [
    plugins: [Shorthand.Quokka.ShortenMaps]
  ]
]
```

On `mix format`, shortenable maps are rewritten to `m(...)` / `sm(...)`, and
`import Shorthand` is added to the module when needed. Structs are left unchanged
(use `st/2` for those).
