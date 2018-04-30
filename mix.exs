defmodule Shorthand.MixProject do
  use Mix.Project

  @version "0.0.2"
  @github_url "https://github.com/andrewtimberlake/shorthand"

  def project do
    [
      app: :shorthand,
      name: "Shorthand",
      description: "Convenience macros to eliminate laborious typing",
      license: "MIT",
      version: @version,
      elixir: "~> 1.3",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: @github_url,
      docs: fn ->
        [
          source_ref: "v#{@version}",
          canonical: "https://hexdocs.pm/shorthand",
          main: "Shorthand",
          source_url: @github_url,
          extras: ["README.md"]
        ]
      end,
      package: [
        maintainers: ["Andrew Timberlake"],
        contributors: ["Andrew Timberlake"],
        licenses: ["MIT"],
        links: %{"GitHub" => @github_url}
      ]
    ]
  end

  def application do
    [
      # extra_applications: [:logger]
    ]
  end

  defp deps do
    [{:ex_doc, "~> 0.0", only: [:docs]}]
  end
end
