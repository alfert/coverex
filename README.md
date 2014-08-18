# Coverex

Coverex is an Elixir Coverage tool used by `mix`. It provides tables with overviews of 
module and function coverage data, includings links to annotated source code files. 

[![Build Status](https://travis-ci.org/alfert/coverex.svg?branch=master)](https://travis-ci.org/alfert/coverex)

## Configuration

You configure Coverex by adding this line to your `mix.exs` file: 

	test_coverage: [tool: Coverex.Task]

as part of the regular project settings. In addition to that, you need to add Coverex 
to the dependencies of your project. Coverex is available via `hex.pm`, so need only to 
add this line to the dependencies in your `mix.exs` file: 

	{:coverex, "~> 0.0.7", only: :test}

For debugging purposes, the log level can be set as addition to the `tool` option. The default
value is `:error`. To set the log level to `:debug` you use this line in your `mix.exs` file: 

	test_coverage: [tool: Coverex.Task, log: :debug]

The usual log levels of `Logger` application of Elixir are available. 

## Running Coverex

If you have configured Coverex as described above you can run Coverex as a drop-in replacement 
for the regular coverage mechanism of mix: 

    $> mix test --cover


## Contributing

Please use the GitHub issue tracker for 

* bug reports and for
* submitting pull requests

## License

Coverex is provided under the Apache 2.0 License. 
