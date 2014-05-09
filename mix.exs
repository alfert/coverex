Code.ensure_loaded?(Hex) and Hex.start

defmodule Coverex.Mixfile do
  use Mix.Project

  def project do
    [app: :coverex,
     version: "0.0.1",
     elixir: "~> 0.13.1",
     package: package,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [ applications: [],
      mod: {Coverex, []} ]
  end

  # List all dependencies in the format:
  #
  # {:foobar, git: "https://github.com/elixir-lang/foobar.git", tag: "0.1"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:ex_doc, github: "elixir-lang/ex_doc" }]
  end

  # Hex Package description
  defp package do
    [contributors: ["Klaus Alfert"],
     licenses: ["Apache 2.0"],
     links: [{"GitHub", "https://github.com/alfert/coverex"}]
    ]
  end

end
