defmodule Shorthand.MixProject do
  use Mix.Project

  @version "1.3.1"
  @github_url "https://github.com/andrewtimberlake/shorthand"

  def project do
    [
      app: :shorthand,
      name: "Shorthand",
      description: """
      Convenience macros to eliminate laborious typing. Provides macros for short map, string keyed map, keyword lists, and structs (ES6 like style)
      """,
      license: "MIT",
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: @github_url,
      docs: fn ->
        [
          source_ref: @version,
          canonical: "https://shorthand.hexdocs.pm",
          main: "Shorthand",
          source_url: @github_url,
          extras: ["README.md"],
          groups_for_modules: [
            Core: [Shorthand],
            Credo: [Shorthand.Check.Refactor.ShortenMaps],
            Quokka: [Shorthand.Quokka.ShortenMaps]
          ]
        ]
      end,
      package: [
        maintainers: ["Andrew Timberlake"],
        contributors: ["Andrew Timberlake"],
        licenses: ["MIT"],
        links: %{"GitHub" => @github_url},
        files: ~w(lib mix.exs README.md)
      ]
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 1.7", optional: true, runtime: false},
      {:quokka, "~> 2.6", optional: true, runtime: false}
    ]
  end
end
