defmodule Coverex.Source do
	@moduledoc """
	This module provides access to the source code the system to be analyzed.
	"""


	def funs_in_mod(mod) do
		{quoted, _source} = get_quoted_source(mod)
		# iterate over quoted and get all functions and their line numbers 
	end
	
	@doc """
	Returns the quoted AST part which defines the given module.
	"""	
	def find_mod(qs, mod) do
		do_find_mod(qs, mod) |> Enum.reject &(&1 == [])
	end
	## TODO:
	## Here fails the handling of nested structures. This requires a 
	## more thought through approach to cope with simple modules,
	## lists of modules in a file and with nested modules as a later step. 
	## Perhaps it is enough iterate through the final list and remove
	## all empty sublists. 
	def do_find_mod(qs, mod) when is_list(qs) do
		Enum.reduce(qs, [], fn(q, acc) -> [do_find_mod(q, mod) | acc] end)
	end
	def do_find_mod({:defmodule, _, [{:__aliases__, _, mod} | t]} = tree, mod), do: tree
	def do_find_mod({:__block__, _, list}, mod) when is_list(list), do: do_find_mod(list, mod)
	def do_find_mod(any, mod) when is_list(any) or is_tuple(any), do: []


	@doc "Returns the aliased module name if there are any dots in its name"
	def alias_mod(mod) when is_atom(mod) do
		mod |> Atom.to_string|> String.split(".") |> 
			Enum.drop(1) |> # first element contains "Elixir" which is not needed here!
			Enum.map &String.to_atom/1 
	end
	

	def get_quoted_source(mod) do
		path = get_source_path(mod)
		{:ok, source} = File.read(path)
		{:ok, quoted} = Code.string_to_quoted(source)
		{quoted, source}
	end
	

	def get_source_path(mod) when is_atom(mod) do
		get_compile_info(mod) |> Keyword.get :source
	end
	
	def get_compile_info(mod) when is_atom(mod) do
		{^mod, beam, filename} = :code.get_object_code(mod)
		case :beam_lib.chunks(beam, [:compile_info]) do
			{:ok, {^mod, [{:compile_info, compile}]}} -> compile
			_ -> []
		end		
	end

end