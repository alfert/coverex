defmodule Coverex.Mixfile do
  use Mix.Project

  def project do
    [app: :coverex,
     version: "1.5.0",
     elixir: ">= 1.6.0",
     package: package(),
     name: "Coverex - Coverage Reports for Elixir",
     source_url: "https://github.com/alfert/coverex",
     homepage_url: "https://github.com/alfert/coverex",
     docs: [readme: "README.md", extra: "CHANGELOG.md"],
     description: description(),
     test_coverage: [tool: Coverex.Task, coveralls: true, ignore_modules: []],
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [ extra_applications: [:logger, :hackney]]
  end

  # List all dependencies in the format:
  #
  # {:foobar, git: "https://github.com/elixir-lang/foobar.git", tag: "0.1"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:hackney, "~> 1.5"},
      {:poison, "~> 3.0 or ~> 3.1 or ~> 4.0"},
      {:earmark, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.13", only: :dev},
      {:dialyxir, "~> 1.0.0-rc3", only: [:dev, :test], runtime: false},
    ]
  end

  # Hex Package description
  defp description do
    """
    Coverex is an Elixir Coverage tool used by mix. It provides tables with overviews of
    module and function coverage data, includings links to annotated source code files and
    supports coveralls.io.
    """
  end

  # Hex Package definition
  defp package do
    [maintainers: ["Klaus Alfert"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/alfert/coverex"}
    ]
  end
end
