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
	def find_mod(qs, mod) when is_list(qs) do
		Enum.reduce(qs, [], fn(q, acc) -> [find_mod(q, mod) | acc] end)
	end
	def find_mod({:defmodule, _, [{:__aliases__, _, mod} | t]} = tree, mod), do: [tree]		
	def find_mod(any, mod) when is_list(any) or is_tuple(any), do: []


	@doc "Returns the aliased module name if there any dots in its name"
	def alias_mod(mod) when is_atom(mod) do
		mod |> atom_to_binary |> String.split(".") |> 
			Enum.drop(1) |> # first element contains "Elixir" which is not needed here!
			Enum.map &binary_to_atom/1 
	end
	

	def get_quoted_source(mod) do
		path = get_source_path(mod)
		{:ok, source} = File.read(path)
		bin_source = String.from_char_data!(source)
		{:ok, quoted} = Code.string_to_quoted(bin_source)
		{quoted, bin_source}
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