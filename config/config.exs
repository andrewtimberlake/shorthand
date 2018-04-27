use Mix.Config

if Mix.env() == :docs do
  config :shorthand, variable_args: false
end
