defmodule Coverex.Source do
	@moduledoc """
	This module provides access to the source code the system to be analyzed.
	"""


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